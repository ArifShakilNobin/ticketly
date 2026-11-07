package com.ticketly.common.dto.search;

import com.ticketly.common.dto.SearchPriority;
import com.ticketly.common.dto.TransportType;

import java.math.BigDecimal;
import java.time.LocalDate;

public record SearchRequest(
        String source,
        String destination,
        LocalDate travelDate,
        TransportType transportType,
        BigDecimal budgetLimit,
        SearchPriority priority,
        String sessionId) {

    public TransportType safeTransportType() {
        return transportType == null ? TransportType.ALL : transportType;
    }

    public SearchPriority safePriority() {
        return priority == null ? SearchPriority.BALANCED : priority;
    }

    public LocalDate safeTravelDate() {
        return travelDate == null ? LocalDate.now() : travelDate;
    }
}
