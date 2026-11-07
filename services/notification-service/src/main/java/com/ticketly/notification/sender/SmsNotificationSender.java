package com.ticketly.notification.sender;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Mock SMS sender: logs the message and reports {@code SENT}. Replace with a real provider by
 * implementing {@link NotificationSender} instead (see the Javadoc there for the swap point).
 */
@Component
public class SmsNotificationSender implements NotificationSender {

    private static final Logger log = LoggerFactory.getLogger(SmsNotificationSender.class);

    @Override
    public String channel() {
        return "SMS";
    }

    @Override
    public String send(String userId, String title, String body) {
        log.info("[MOCK SMS] to={} | {} | {}", userId, title, body);
        return "SENT";
    }
}
