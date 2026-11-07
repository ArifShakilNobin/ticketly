package com.ticketly.booking.service;

import com.ticketly.booking.client.CostEngineClient;
import com.ticketly.booking.domain.Booking;
import com.ticketly.booking.events.BookingEventPublisher;
import com.ticketly.booking.payment.PaymentGateway;
import com.ticketly.booking.payment.PaymentResult;
import com.ticketly.booking.repo.BookingRepository;
import com.ticketly.common.dto.BookingStatus;
import com.ticketly.common.dto.PaymentMethod;
import com.ticketly.common.dto.booking.BookingResponse;
import com.ticketly.common.dto.booking.CancelRequest;
import com.ticketly.common.dto.booking.CreateBookingRequest;
import com.ticketly.common.dto.cost.OptimizeRequest;
import com.ticketly.common.dto.cost.OptimizeResponse;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.OptimizedFare;
import com.ticketly.common.dto.search.PriceBreakdown;
import com.ticketly.common.event.BookingCancelledEvent;
import com.ticketly.common.event.BookingConfirmedEvent;
import com.ticketly.common.security.CurrentUser;
import com.ticketly.common.web.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Booking lifecycle: validate the fare → price it through the cost engine → persist PENDING →
 * charge through the {@link PaymentGateway} → CONFIRMED (PNR + Kafka event) or FAILED.
 */
@Service
public class BookingService {

    private static final Logger log = LoggerFactory.getLogger(BookingService.class);

    private final BookingRepository bookings;
    private final CostEngineClient costEngine;
    private final PaymentGateway paymentGateway;
    private final BookingEventPublisher events;
    private final BigDecimal convenienceFee;

    public BookingService(BookingRepository bookings,
                          CostEngineClient costEngine,
                          PaymentGateway paymentGateway,
                          BookingEventPublisher events,
                          @Value("${cost.convenience-fee:20}") BigDecimal convenienceFee) {
        this.bookings = bookings;
        this.costEngine = costEngine;
        this.paymentGateway = paymentGateway;
        this.events = events;
        this.convenienceFee = convenienceFee;
    }

    // ---------------------------------------------------------------- create

    @Transactional
    public BookingResponse create(CurrentUser user, CreateBookingRequest request) {
        FareItem fare = request.fare();
        if (fare == null) {
            throw ApiException.badRequest("fare is required");
        }
        int quantity = request.quantity();
        if (fare.seatsAvailable() < quantity) {
            throw ApiException.conflict("Not enough seats: " + fare.seatsAvailable() + " available, " + quantity + " requested");
        }

        PriceBreakdown price = resolvePrice(fare, request);

        Booking booking = new Booking(
                user.id(),
                request.searchId(),
                BookingStatus.PENDING,
                fare,
                price,
                request.passengerName().trim(),
                request.passengerPhone().trim(),
                quantity,
                request.paymentMethod().name(),
                blankToNull(request.mfsProvider()));
        booking = bookings.save(booking);
        log.info("Created booking {} (PENDING) for user {}", booking.getId(), user.id());

        BigDecimal amount = booking.totalAmount();
        PaymentResult result = paymentGateway.charge(
                amount, request.paymentMethod(), request.mfsProvider(), request.cardLast4());

        if (result.success()) {
            booking.setStatus(BookingStatus.CONFIRMED);
            booking.setPnr(uniquePnr());
            booking.setTransactionId(result.transactionId());
            booking.touch();
            booking = bookings.save(booking);
            log.info("Booking {} CONFIRMED with PNR {} ({} BDT)", booking.getId(), booking.getPnr(), amount);
            publishConfirmed(booking);
        } else {
            booking.setStatus(BookingStatus.FAILED);
            booking.setFailureReason(result.failureReason());
            booking.touch();
            booking = bookings.save(booking);
            log.warn("Booking {} FAILED payment: {}", booking.getId(), result.failureReason());
            // no event on failure
        }
        return toResponse(booking);
    }

    /**
     * Asks the cost engine for the authoritative breakdown. When the engine is unreachable or
     * answers nothing usable we fall back locally (base fare + convenience fee, no discounts) and
     * log a WARN — a booking must never fail because the pricing service is down.
     */
    private PriceBreakdown resolvePrice(FareItem fare, CreateBookingRequest request) {
        try {
            String method = request.paymentMethod().name();
            if (request.paymentMethod() == PaymentMethod.MFS && request.mfsProvider() != null
                    && !request.mfsProvider().isBlank()) {
                method = method + ":" + request.mfsProvider().trim();
            }
            OptimizeRequest optimizeRequest = new OptimizeRequest(
                    List.of(fare), List.of(method), null, null, request.promoCode());
            OptimizeResponse response = costEngine.optimize(optimizeRequest);
            if (response != null && response.items() != null && !response.items().isEmpty()) {
                OptimizedFare priced = response.items().get(0);
                if (priced != null && priced.price() != null) {
                    return priced.price();
                }
            }
            log.warn("Cost engine returned no price for fare {}; falling back to base fare + fee", fare.id());
        } catch (Exception ex) {
            log.warn("Cost engine unavailable ({}); falling back to base fare + fee", ex.getMessage());
        }
        return fallbackPrice(fare);
    }

    private PriceBreakdown fallbackPrice(FareItem fare) {
        BigDecimal base = fare.baseFare() == null ? BigDecimal.ZERO : fare.baseFare().setScale(2);
        BigDecimal fee = convenienceFee == null ? new BigDecimal("20.00") : convenienceFee.setScale(2);
        BigDecimal effective = base.add(fee);
        return new PriceBreakdown(base, new BigDecimal("0.00"), new BigDecimal("0.00"),
                fee, effective, new BigDecimal("0.00"));
    }

    // ---------------------------------------------------------------- read

    @Transactional(readOnly = true)
    public List<BookingResponse> listFor(String userId) {
        return bookings.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(BookingService::toResponse)
                .toList();
    }

    /** 404 both when it does not exist and when it belongs to somebody else (no existence leak). */
    @Transactional(readOnly = true)
    public BookingResponse get(String userId, String bookingId) {
        return toResponse(requireOwned(userId, bookingId));
    }

    // ---------------------------------------------------------------- cancel

    @Transactional
    public BookingResponse cancel(String userId, String bookingId, CancelRequest request) {
        Booking booking = requireOwned(userId, bookingId);
        // throws 409 when the current status forbids cancellation
        booking.setStatus(BookingTransitions.cancel(booking.getStatus()));
        booking.setCancelReason(normalizeReason(request == null ? null : request.reason()));
        booking.touch();
        Booking saved = bookings.save(booking);
        log.info("Booking {} CANCELLED: {}", saved.getId(), saved.getCancelReason());
        events.bookingCancelled(new BookingCancelledEvent(
                saved.getId(), saved.getPnr(), saved.getUserId(), saved.getCancelReason(), Instant.now()));
        return toResponse(saved);
    }

    // ---------------------------------------------------------------- helpers

    private Booking requireOwned(String userId, String bookingId) {
        if (bookingId == null || bookingId.isBlank()) {
            throw ApiException.notFound("Booking not found");
        }
        return bookings.findByIdAndUserId(bookingId.trim(), userId)
                .orElseThrow(() -> ApiException.notFound("Booking not found"));
    }

    private String uniquePnr() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String pnr = PnrGenerator.generate();
            if (!bookings.existsByPnr(pnr)) {
                return pnr;
            }
        }
        // 36^6 ≈ 2 billion combinations: reaching here is practically impossible
        throw ApiException.conflict("Could not allocate a unique PNR, please retry");
    }

    private void publishConfirmed(Booking booking) {
        FareItem fare = booking.getFare();
        PriceBreakdown price = booking.getPrice();
        events.bookingConfirmed(new BookingConfirmedEvent(
                booking.getId(),
                booking.getPnr(),
                booking.getUserId(),
                booking.getPassengerName(),
                booking.getPassengerPhone(),
                fare == null ? "" : fare.route(),
                fare == null || fare.departTime() == null ? "" : fare.departTime().toString(),
                price == null ? BigDecimal.ZERO : price.effectivePrice(),
                booking.getPaymentMethod(),
                booking.getMfsProvider(),
                booking.getQuantity(),
                booking.getCreatedAt()));
    }

    private static String normalizeReason(String reason) {
        return reason == null || reason.isBlank() ? "Cancelled by user" : reason.trim();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static BookingResponse toResponse(Booking booking) {
        return new BookingResponse(
                booking.getId(),
                booking.getPnr(),
                booking.getStatus(),
                booking.getFare(),
                booking.getPrice(),
                booking.getPassengerName(),
                booking.getPassengerPhone(),
                booking.getQuantity(),
                booking.getPaymentMethod(),
                booking.getMfsProvider(),
                booking.getTransactionId(),
                booking.getFailureReason(),
                booking.getCreatedAt(),
                booking.getUpdatedAt());
    }
}
