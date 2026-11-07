package com.ticketly.notification.sender;

/**
 * Delivery back-end for a notification channel.
 *
 * <p><b>Swap point:</b> {@link com.ticketly.notification.sender.SmsNotificationSender} is the
 * default (mock) implementation. To integrate a real provider (e.g. an SMS gateway or an e-mail
 * transport) implement this interface and register the bean — the listener picks up whichever
 * implementation is injected.</p>
 */
public interface NotificationSender {

    /** The channel this sender delivers, e.g. {@code "SMS"}. */
    String channel();

    /**
     * Delivers the message.
     *
     * @return the resulting status, e.g. {@code "SENT"} or {@code "FAILED"}
     */
    String send(String userId, String title, String body);
}
