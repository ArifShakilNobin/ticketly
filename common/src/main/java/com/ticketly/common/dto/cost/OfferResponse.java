package com.ticketly.common.dto.cost;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/** An active MFS cashback / bank / promo offer. */
public record OfferResponse(
        String id,
        String title,
        String provider,
        String cashbackType,
        BigDecimal cashbackPercent,
        BigDecimal cashbackAmount,
        BigDecimal maxCashback,
        BigDecimal minFare,
        List<String> paymentMethods,
        Instant validFrom,
        Instant validTo,
        boolean active) {
}
