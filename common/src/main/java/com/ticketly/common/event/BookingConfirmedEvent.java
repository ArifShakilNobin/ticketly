package com.ticketly.common.event;

import java.math.BigDecimal;
import java.time.Instant;

/** Published on {@code booking.confirmed} once payment succeeds. */
public record BookingConfirmedEvent(
        String bookingId,
        String pnr,
        String userId,
        String passengerName,
        String passengerPhone,
        String route,
        String departTime,
        BigDecimal effectivePrice,
        String paymentMethod,
        String mfsProvider,
        int quantity,
        Instant createdAt) {
}
