package com.ticketly.notification.service;

import com.ticketly.common.event.BookingCancelledEvent;
import com.ticketly.common.event.BookingConfirmedEvent;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Composes notification messages from booking events.
 *
 * <p>Pure static logic (no Spring, no Mongo) so the exact wording can be unit tested. The listener
 * in {@link BookingNotificationListener} is a thin wrapper around this class.</p>
 */
public final class NotificationMessageFactory {

    public static final String CHANNEL_SMS = "SMS";

    public static final String TITLE_CONFIRMED = "টিকিট কনফার্ম হয়েছে / Booking confirmed";
    public static final String TITLE_CANCELLED = "বাতিল হয়েছে / Booking cancelled";

    private NotificationMessageFactory() {
    }

    /** A composed message: which channel, which title, which body. */
    public record Composed(String channel, String title, String body) {
    }

    /**
     * "PNR {pnr}: {passengerName}, {route}, {departTime} — ৳{effectivePrice} ({paymentMethod})."
     */
    public static Composed confirmed(BookingConfirmedEvent event) {
        String payment = paymentLabel(event.paymentMethod(), event.mfsProvider());
        String body = String.format("PNR %s: %s, %s, %s — ৳%s (%s).",
                orEmpty(event.pnr()),
                orEmpty(event.passengerName()),
                orEmpty(event.route()),
                orEmpty(event.departTime()),
                money(event.effectivePrice()),
                payment);
        return new Composed(CHANNEL_SMS, TITLE_CONFIRMED, body);
    }

    /** "PNR {pnr} cancelled. Reason: {reason}." */
    public static Composed cancelled(BookingCancelledEvent event) {
        String reason = event.reason() == null || event.reason().isBlank()
                ? "no reason provided"
                : event.reason().trim();
        String body = String.format("PNR %s cancelled. Reason: %s.", orEmpty(event.pnr()), reason);
        return new Composed(CHANNEL_SMS, TITLE_CANCELLED, body);
    }

    /** {@code "MFS"} or {@code "MFS:bKash"} / {@code "CARD"}. */
    static String paymentLabel(String paymentMethod, String mfsProvider) {
        String method = orEmpty(paymentMethod);
        if (mfsProvider != null && !mfsProvider.isBlank()) {
            return method + ":" + mfsProvider.trim();
        }
        return method;
    }

    /** Money is always shown with two decimals, e.g. {@code 970.00}. */
    static String money(BigDecimal amount) {
        if (amount == null) {
            return "0.00";
        }
        return amount.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }

    private static String orEmpty(String value) {
        return value == null ? "" : value;
    }
}
