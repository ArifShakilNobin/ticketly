package com.ticketly.common.dto.booking;

import com.ticketly.common.dto.PaymentMethod;
import com.ticketly.common.dto.search.FareItem;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;

public record CreateBookingRequest(
        String searchId,
        @NotNull(message = "fare is required") FareItem fare,
        @NotBlank(message = "passengerName is required") String passengerName,
        @NotBlank(message = "passengerPhone is required") String passengerPhone,
        @NotNull(message = "quantity is required") @Min(value = 1, message = "quantity must be at least 1") Integer quantity,
        @NotNull(message = "paymentMethod is required") PaymentMethod paymentMethod,
        String mfsProvider,
        String cardLast4,
        String promoCode) {
}
