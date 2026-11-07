package com.ticketly.booking.payment;

import com.ticketly.common.dto.PaymentMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * Simulated gateway used until the real MFS/card providers are integrated. Every decision is logged
 * so the flow is easy to follow.
 *
 * <ul>
 *   <li>MFS → success unless the provider is blank or not bKash/Nagad/Rocket</li>
 *   <li>CARD → success only with a 4-digit {@code cardLast4}, otherwise DECLINED "Card details missing"</li>
 *   <li>amount &gt; {@code payment.mock.max-amount} → DECLINED "Amount limit exceeded"</li>
 *   <li>{@code payment.mock.force-failure=true} → always DECLINED (for testing)</li>
 * </ul>
 *
 * <p>Swap point: set {@code payment.provider} to another value and register a different
 * {@link PaymentGateway} bean — this component backs off automatically.</p>
 */
@Component
@ConditionalOnProperty(name = "payment.provider", havingValue = "mock", matchIfMissing = true)
public class MockPaymentGateway implements PaymentGateway {

    private static final Logger log = LoggerFactory.getLogger(MockPaymentGateway.class);

    private static final Set<String> SUPPORTED_MFS = Set.of("bKash", "Nagad", "Rocket");

    private final BigDecimal maxAmount;
    private final boolean forceFailure;

    public MockPaymentGateway(@Value("${payment.mock.max-amount:500000}") BigDecimal maxAmount,
                              @Value("${payment.mock.force-failure:false}") boolean forceFailure) {
        this.maxAmount = maxAmount;
        this.forceFailure = forceFailure;
        log.info("Mock payment gateway initialised (maxAmount={}, forceFailure={})", maxAmount, forceFailure);
    }

    @Override
    public PaymentResult charge(BigDecimal amount, PaymentMethod method, String mfsProvider, String cardLast4) {
        log.info("Mock charge requested: amount={}, method={}, mfsProvider={}, cardLast4={}",
                amount, method, mfsProvider, mask(cardLast4));

        if (forceFailure) {
            log.warn("Mock charge DECLINED (forced failure flag): {} BDT", amount);
            return PaymentResult.declined("Forced failure enabled");
        }
        if (amount != null && maxAmount != null && amount.compareTo(maxAmount) > 0) {
            log.warn("Mock charge DECLINED: amount {} exceeds limit {}", amount, maxAmount);
            return PaymentResult.declined("Amount limit exceeded");
        }
        if (method == null) {
            log.warn("Mock charge DECLINED: no payment method");
            return PaymentResult.declined("Payment method missing");
        }
        if (method == PaymentMethod.MFS) {
            String provider = mfsProvider == null ? "" : mfsProvider.trim();
            if (provider.isEmpty()) {
                log.warn("Mock charge DECLINED: MFS provider missing");
                return PaymentResult.declined("MFS provider missing");
            }
            if (!SUPPORTED_MFS.contains(provider)) {
                log.warn("Mock charge DECLINED: unsupported MFS provider '{}'", provider);
                return PaymentResult.declined("Unsupported MFS provider: " + provider);
            }
            String transactionId = newTransactionId("MFS");
            log.info("Mock charge APPROVED via {}: transactionId={}", provider, transactionId);
            return PaymentResult.success(transactionId);
        }
        // CARD
        String last4 = cardLast4 == null ? "" : cardLast4.trim();
        if (!last4.matches("\\d{4}")) {
            log.warn("Mock charge DECLINED: card details missing or not 4 digits");
            return PaymentResult.declined("Card details missing");
        }
        String transactionId = newTransactionId("CARD");
        log.info("Mock charge APPROVED via CARD ****{}: transactionId={}", last4, transactionId);
        return PaymentResult.success(transactionId);
    }

    private static String newTransactionId(String channel) {
        return "TXN-" + channel + "-" + UUID.randomUUID().toString().toUpperCase(Locale.ROOT);
    }

    private static String mask(String cardLast4) {
        if (cardLast4 == null || cardLast4.isBlank()) {
            return null;
        }
        return "****" + cardLast4.trim();
    }
}
