package com.ticketly.nlp.parser;

import com.ticketly.common.dto.SearchPriority;
import com.ticketly.common.dto.TicketIntent;
import com.ticketly.common.dto.TransportType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Structured output of the rule-based query parser (before session/text wrapping). */
public record ParsedQuery(
        TicketIntent intent,
        String source,
        String destination,
        TransportType transportType,
        LocalDate travelDate,
        BigDecimal budgetLimit,
        SearchPriority priority,
        double confidence,
        List<String> detectedTerms) {

    public boolean hasRoute() {
        return source != null || destination != null;
    }

    public boolean hasFullRoute() {
        return source != null && destination != null;
    }
}
