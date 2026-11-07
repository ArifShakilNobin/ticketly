package com.ticketly.booking.service;

import com.ticketly.common.dto.BookingStatus;
import com.ticketly.common.web.ApiException;

/**
 * Booking status transition rules. Pure logic (no Spring) so it can be unit tested directly.
 */
public final class BookingTransitions {

    private BookingTransitions() {
    }

    /**
     * Cancellation is only allowed from {@code PENDING} or {@code CONFIRMED}; anything else
     * ({@code CANCELLED}, {@code FAILED}) is a conflict.
     *
     * @return the resulting status ({@code CANCELLED})
     * @throws ApiException with 409 when the current status forbids cancellation
     */
    public static BookingStatus cancel(BookingStatus current) {
        if (current == null) {
            throw ApiException.badRequest("Booking has no status");
        }
        if (current != BookingStatus.PENDING && current != BookingStatus.CONFIRMED) {
            throw ApiException.conflict("A booking in status " + current + " cannot be cancelled");
        }
        return BookingStatus.CANCELLED;
    }

    /** Whether a booking can still be cancelled. */
    public static boolean canCancel(BookingStatus current) {
        return current == BookingStatus.PENDING || current == BookingStatus.CONFIRMED;
    }
}
