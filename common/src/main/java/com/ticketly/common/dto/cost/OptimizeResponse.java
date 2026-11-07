package com.ticketly.common.dto.cost;

import com.ticketly.common.dto.search.OptimizedFare;

import java.time.Instant;
import java.util.List;

public record OptimizeResponse(
        List<OptimizedFare> items,
        String cheapestId,
        String recommendedId,
        Instant generatedAt) {
}
