package com.ticketly.booking.payment;

import com.ticketly.common.dto.PaymentMethod;

import java.math.BigDecimal;

/**
 * Payment provider abstraction. {@link MockPaymentGateway} is the default; a real bKash / Nagad /
 * card gateway can be dropped in behind the same interface by registering another bean with
 * {@code @ConditionalOnProperty(name = "payment.provider", havingValue = "...")}.
 */
public interface PaymentGateway {

    /**
     * Attempts to charge {@code amount} (BDT).
     *
     * @param amount     total amount to charge
     * @param method     MFS or CARD
     * @param mfsProvider bKash / Nagad / Rocket (MFS only)
     * @param cardLast4  last four digits of the card (CARD only)
     * @return never {@code null}: either a success with a transaction id or a decline with a reason
     */
    PaymentResult charge(BigDecimal amount, PaymentMethod method, String mfsProvider, String cardLast4);
}
