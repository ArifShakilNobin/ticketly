package com.ticketly.common.dto.search;

import com.ticketly.common.dto.TransportType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Map;

/** A raw fare returned by a transport provider, before discounts are applied. */
public record FareItem(
        String id,
        String provider,
        String providerRef,
        TransportType transportType,
        String source,
        String destination,
        LocalDate travelDate,
        LocalTime departTime,
        LocalTime arriveTime,
        int durationMins,
        BigDecimal baseFare,
        String currency,
        int seatsAvailable,
        String vehicleClass,
        String cancellationPolicy,
        Map<String, String> meta) {

    public String route() {
        return source + " → " + destination;
    }
}
