package com.ticketly.common.dto.search;

import com.ticketly.common.dto.TransportType;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public record SearchResponse(
        String searchId,
        String source,
        String destination,
        LocalDate travelDate,
        TransportType transportType,
        List<OptimizedFare> items,
        boolean cached,
        int totalFound,
        Instant generatedAt) {
}
