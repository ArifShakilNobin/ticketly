package com.ticketly.common.dto.search;

import java.util.List;

/** A fare enriched with its price breakdown and applicable offers. */
public record OptimizedFare(FareItem fare, PriceBreakdown price, List<String> appliedOffers, String badge) {
}
