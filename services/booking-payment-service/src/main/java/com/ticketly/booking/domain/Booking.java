package com.ticketly.booking.domain;

import com.ticketly.common.dto.BookingStatus;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.PriceBreakdown;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

/**
 * A booking. {@code fare} and {@code price} are immutable JSON snapshots taken at booking time so a
 * later price change never rewrites history.
 */
@Entity
@Table(name = "bookings")
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    /** Assigned once payment succeeds; unique but null while PENDING/FAILED. */
    @Column(length = 12, unique = true)
    private String pnr;

    @Column(nullable = false, length = 64)
    private String userId;

    @Column(length = 64)
    private String searchId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private BookingStatus status;

    @Convert(converter = FareJsonConverter.class)
    @Column(columnDefinition = "text")
    private FareItem fare;

    @Convert(converter = PriceJsonConverter.class)
    @Column(columnDefinition = "text")
    private PriceBreakdown price;

    @Column(nullable = false, length = 120)
    private String passengerName;

    @Column(nullable = false, length = 24)
    private String passengerPhone;

    @Column(nullable = false)
    private int quantity;

    /** MFS or CARD (name of {@link com.ticketly.common.dto.PaymentMethod}). */
    @Column(nullable = false, length = 10)
    private String paymentMethod;

    @Column(length = 20)
    private String mfsProvider;

    @Column(length = 64)
    private String transactionId;

    /** Set when the payment was declined. */
    @Column(length = 300)
    private String failureReason;

    /** Set when the passenger cancelled the booking. */
    @Column(length = 300)
    private String cancelReason;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    protected Booking() {
    }

    public Booking(String userId, String searchId, BookingStatus status, FareItem fare,
                   PriceBreakdown price, String passengerName, String passengerPhone,
                   int quantity, String paymentMethod, String mfsProvider) {
        Instant now = Instant.now();
        this.userId = userId;
        this.searchId = searchId;
        this.status = status;
        this.fare = fare;
        this.price = price;
        this.passengerName = passengerName;
        this.passengerPhone = passengerPhone;
        this.quantity = quantity;
        this.paymentMethod = paymentMethod;
        this.mfsProvider = mfsProvider;
        this.createdAt = now;
        this.updatedAt = now;
    }

    /** Total charged for this booking: the per-ticket effective price × quantity. */
    public java.math.BigDecimal totalAmount() {
        java.math.BigDecimal perTicket = price == null || price.effectivePrice() == null
                ? java.math.BigDecimal.ZERO
                : price.effectivePrice();
        return perTicket.multiply(java.math.BigDecimal.valueOf(quantity));
    }

    public void touch() {
        this.updatedAt = Instant.now();
    }

    public String getId() {
        return id;
    }

    public String getPnr() {
        return pnr;
    }

    public void setPnr(String pnr) {
        this.pnr = pnr;
    }

    public String getUserId() {
        return userId;
    }

    public String getSearchId() {
        return searchId;
    }

    public BookingStatus getStatus() {
        return status;
    }

    public void setStatus(BookingStatus status) {
        this.status = status;
    }

    public FareItem getFare() {
        return fare;
    }

    public PriceBreakdown getPrice() {
        return price;
    }

    public String getPassengerName() {
        return passengerName;
    }

    public String getPassengerPhone() {
        return passengerPhone;
    }

    public int getQuantity() {
        return quantity;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public String getMfsProvider() {
        return mfsProvider;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public String getFailureReason() {
        return failureReason;
    }

    public void setFailureReason(String failureReason) {
        this.failureReason = failureReason;
    }

    public String getCancelReason() {
        return cancelReason;
    }

    public void setCancelReason(String cancelReason) {
        this.cancelReason = cancelReason;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
