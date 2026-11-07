package com.ticketly.notification.api;

/** Response of {@code GET /api/v1/notifications/unread-count}. */
public record UnreadCountResponse(long count) {
}
