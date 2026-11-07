package com.ticketly.booking.api;

import com.ticketly.booking.service.BookingService;
import com.ticketly.common.dto.booking.BookingResponse;
import com.ticketly.common.dto.booking.CancelRequest;
import com.ticketly.common.dto.booking.CreateBookingRequest;
import com.ticketly.common.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Booking endpoints — every call needs a valid JWT (see SecurityConfig). */
@RestController
@RequestMapping("/api/v1/bookings")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @PostMapping
    public ResponseEntity<BookingResponse> create(@AuthenticationPrincipal CurrentUser user,
                                                  @Valid @RequestBody CreateBookingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(bookingService.create(user, request));
    }

    /** The current user's bookings, newest first. */
    @GetMapping
    public List<BookingResponse> list(@AuthenticationPrincipal CurrentUser user) {
        return bookingService.listFor(user.id());
    }

    /** 200 for the owner, 404 otherwise (also when it does not exist — no existence leak). */
    @GetMapping("/{id}")
    public BookingResponse get(@AuthenticationPrincipal CurrentUser user, @PathVariable("id") String id) {
        return bookingService.get(user.id(), id);
    }

    @PostMapping("/{id}/cancel")
    public BookingResponse cancel(@AuthenticationPrincipal CurrentUser user,
                                  @PathVariable("id") String id,
                                  @RequestBody(required = false) CancelRequest request) {
        return bookingService.cancel(user.id(), id, request);
    }
}
