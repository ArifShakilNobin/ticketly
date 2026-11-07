package com.ticketly.common.dto.search;

import java.math.BigDecimal;

/**
 * Effective Price = Base Fare - MFS Cashback - Promo Discount + Convenience Fee
 */
public record PriceBreakdown(
        BigDecimal baseFare,
        BigDecimal mfsCashback,
        BigDecimal promoDiscount,
        BigDecimal convenienceFee,
        BigDecimal effectivePrice,
        BigDecimal savedAmount) {
}
