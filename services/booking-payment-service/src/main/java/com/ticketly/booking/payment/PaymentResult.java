package com.ticketly.booking.payment;

/** Outcome of a charge attempt. */
public record PaymentResult(boolean success, String transactionId, String failureReason) {

    public static PaymentResult success(String transactionId) {
        return new PaymentResult(true, transactionId, null);
    }

    public static PaymentResult declined(String reason) {
        return new PaymentResult(false, null, reason);
    }
}
