package com.ticketly.booking.payment;

import com.ticketly.common.dto.PaymentMethod;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The mock gateway decision table: MFS ok / MFS declined, CARD ok / CARD declined, plus the amount
 * limit and the forced-failure test flag.
 */
class MockPaymentGatewayTest {

    private final MockPaymentGateway gateway = new MockPaymentGateway(new BigDecimal("500000"), false);

    // ---- branch 1: MFS succeeds for a supported provider

    @Test
    void mfsSucceedsForSupportedProviders() {
        for (String provider : new String[]{"bKash", "Nagad", "Rocket"}) {
            PaymentResult result = gateway.charge(new BigDecimal("1500.00"), PaymentMethod.MFS, provider, null);
            assertTrue(result.success(), "MFS with " + provider + " should succeed");
            assertNotNull(result.transactionId());
        }
    }

    // ---- branch 2: MFS declines without a (supported) provider

    @Test
    void mfsDeclinesWhenProviderIsBlankOrUnsupported() {
        PaymentResult blank = gateway.charge(new BigDecimal("1500.00"), PaymentMethod.MFS, "  ", null);
        assertFalse(blank.success());
        assertEquals("MFS provider missing", blank.failureReason());

        PaymentResult unknown = gateway.charge(new BigDecimal("1500.00"), PaymentMethod.MFS, "Paytm", null);
        assertFalse(unknown.success());
        assertEquals("Unsupported MFS provider: Paytm", unknown.failureReason());
    }

    // ---- branch 3: CARD succeeds with 4 digits

    @Test
    void cardSucceedsWithFourDigits() {
        PaymentResult result = gateway.charge(new BigDecimal("2500.00"), PaymentMethod.CARD, null, "1234");

        assertTrue(result.success());
        assertNotNull(result.transactionId());
        assertTrue(result.transactionId().startsWith("TXN-CARD-"));
    }

    // ---- branch 4: CARD declines without card details

    @Test
    void cardDeclinesWithoutCardDetails() {
        PaymentResult missing = gateway.charge(new BigDecimal("2500.00"), PaymentMethod.CARD, null, null);
        assertFalse(missing.success());
        assertEquals("Card details missing", missing.failureReason());

        PaymentResult notFourDigits = gateway.charge(new BigDecimal("2500.00"), PaymentMethod.CARD, null, "12a4");
        assertFalse(notFourDigits.success());
        assertEquals("Card details missing", notFourDigits.failureReason());
    }

    // ---- amount limit

    @Test
    void amountOverTheConfiguredLimitIsDeclined() {
        PaymentResult overLimit = gateway.charge(new BigDecimal("500000.01"), PaymentMethod.MFS, "bKash", null);
        assertFalse(overLimit.success());
        assertEquals("Amount limit exceeded", overLimit.failureReason());

        // exactly at the limit is still allowed
        assertTrue(gateway.charge(new BigDecimal("500000.00"), PaymentMethod.MFS, "bKash", null).success());
    }

    // ---- forced failure flag

    @Test
    void forceFailureFlagDeclinesEverything() {
        MockPaymentGateway broken = new MockPaymentGateway(new BigDecimal("500000"), true);

        PaymentResult result = broken.charge(new BigDecimal("100.00"), PaymentMethod.MFS, "bKash", null);

        assertFalse(result.success());
        assertEquals("Forced failure enabled", result.failureReason());
    }
}
