package com.ticketly.common.dto.booking;

import com.ticketly.common.dto.BookingStatus;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.PriceBreakdown;

import java.time.Instant;

public record BookingResponse(
        String id,
        String pnr,
        BookingStatus status,
        FareItem fare,
        PriceBreakdown price,
        String passengerName,
        String passengerPhone,
        int quantity,
        String paymentMethod,
        String mfsProvider,
        String transactionId,
        String failureReason,
        Instant createdAt,
        Instant updatedAt) {
}
