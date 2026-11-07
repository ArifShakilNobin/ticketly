package com.ticketly.common.dto.nlp;

import com.ticketly.common.dto.TicketIntent;
import com.ticketly.common.dto.TransportType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Structured result of the voice/NLP pipeline. */
public record ParsedQueryResponse(
        String sessionId,
        String text,
        String transcript,
        TicketIntent intent,
        String source,
        String destination,
        TransportType transportType,
        LocalDate travelDate,
        BigDecimal budgetLimit,
        String priority,
        double confidence,
        List<String> detectedTerms) {
}
