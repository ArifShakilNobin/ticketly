package com.ticketly.notification.service;

import com.ticketly.common.dto.notification.NotificationResponse;
import com.ticketly.common.web.ApiException;
import com.ticketly.notification.domain.Notification;
import com.ticketly.notification.repo.NotificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Read side of the notifications: list for the current user, unread count, mark as read. */
@Service
public class NotificationService {

    /** Newest first, hard capped. */
    private static final int MAX_NOTIFICATIONS = 50;

    private final NotificationRepository notifications;

    public NotificationService(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> listFor(String userId) {
        return notifications.findTop50ByUserIdOrderBySentAtDesc(userId).stream()
                .limit(MAX_NOTIFICATIONS)
                .map(NotificationService::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public long unreadCount(String userId) {
        return notifications.countByUserIdAndReadFalse(userId);
    }

    /** Marks one notification as read; 404 when it does not exist or belongs to somebody else. */
    @Transactional
    public NotificationResponse markRead(String userId, String id) {
        Notification notification = notifications.findByIdAndUserId(id, userId)
                .orElseThrow(() -> ApiException.notFound("Notification not found"));
        notification.setRead(true);
        return toResponse(notifications.save(notification));
    }

    private static NotificationResponse toResponse(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getUserId(),
                notification.getChannel(),
                notification.getTitle(),
                notification.getBody(),
                notification.getStatus(),
                notification.getRelatedId(),
                notification.getSentAt());
    }
}
