package com.ticketly.common.event;

import java.time.Instant;

/** Published on {@code booking.cancelled}. */
public record BookingCancelledEvent(
        String bookingId,
        String pnr,
        String userId,
        String reason,
        Instant cancelledAt) {
}
