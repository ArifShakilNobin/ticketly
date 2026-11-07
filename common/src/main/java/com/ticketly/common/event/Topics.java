package com.ticketly.common.event;

/** Kafka topic names shared across the platform. */
public final class Topics {

    public static final String BOOKING_CONFIRMED = "booking.confirmed";
    public static final String BOOKING_CANCELLED = "booking.cancelled";
    public static final String SEARCH_PERFORMED = "search.performed";

    private Topics() {
    }
}
