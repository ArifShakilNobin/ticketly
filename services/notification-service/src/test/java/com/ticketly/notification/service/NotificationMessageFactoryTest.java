package com.ticketly.notification.service;

import com.ticketly.common.event.BookingCancelledEvent;
import com.ticketly.common.event.BookingConfirmedEvent;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Pure unit tests for the message wording — no Spring, no Mongo, no Kafka.
 */
class NotificationMessageFactoryTest {

    private static final Instant NOW = Instant.parse("2026-11-07T10:00:00Z");

    @Test
    void confirmedMessageIsComposedFromTheEvent() {
        BookingConfirmedEvent event = new BookingConfirmedEvent(
                "b-1", "TK7H2QX9", "u-42", "Rahim Uddin", "01711111111",
                "Dhaka → Chittagong", "08:00",
                new BigDecimal("970.00"), "MFS", "bKash", 2, NOW);

        NotificationMessageFactory.Composed message = NotificationMessageFactory.confirmed(event);

        assertEquals("SMS", message.channel());
        assertEquals("টিকিট কনফার্ম হয়েছে / Booking confirmed", message.title());
        assertEquals(
                "PNR TK7H2QX9: Rahim Uddin, Dhaka → Chittagong, 08:00 — ৳970.00 (MFS:bKash).",
                message.body());
    }

    @Test
    void confirmedMessageWithoutMfsProviderUsesThePlainMethod() {
        BookingConfirmedEvent event = new BookingConfirmedEvent(
                "b-2", "TKAAAAAA", "u-1", "Karim", "01822222222",
                "Dhaka → Sylhet", "14:30",
                new BigDecimal("1500"), "CARD", null, 1, NOW);

        String body = NotificationMessageFactory.confirmed(event).body();

        // CARD has no provider suffix and the price is normalised to two decimals
        assertTrue(body.endsWith("(CARD)."), body);
        assertTrue(body.contains("৳1500.00"), body);
    }

    @Test
    void cancelledMessageCarriesPnrAndReason() {
        BookingCancelledEvent event = new BookingCancelledEvent(
                "b-3", "TKZZ9988", "u-42", "Passenger changed plans", NOW);

        NotificationMessageFactory.Composed message = NotificationMessageFactory.cancelled(event);

        assertEquals("SMS", message.channel());
        assertEquals("বাতিল হয়েছে / Booking cancelled", message.title());
        assertEquals("PNR TKZZ9988 cancelled. Reason: Passenger changed plans.", message.body());
    }

    @Test
    void cancelledMessageToleratesMissingReasonAndPnr() {
        BookingCancelledEvent event = new BookingCancelledEvent("b-4", null, "u-1", null, NOW);

        String body = NotificationMessageFactory.cancelled(event).body();

        assertEquals("PNR  cancelled. Reason: no reason provided.", body);
    }
}
