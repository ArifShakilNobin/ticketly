package com.ticketly.common.dto.notification;

import java.time.Instant;

public record NotificationResponse(
        String id,
        String userId,
        String channel,
        String title,
        String body,
        String status,
        String relatedId,
        Instant sentAt) {
}
