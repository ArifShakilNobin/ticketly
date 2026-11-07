package com.ticketly.notification.api;

import com.ticketly.common.dto.notification.NotificationResponse;
import com.ticketly.notification.service.NotificationService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import com.ticketly.common.security.CurrentUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Notification endpoints — every call needs a valid JWT (see SecurityConfig). */
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    /** The current user's notifications, newest first, max 50. */
    @GetMapping
    public List<NotificationResponse> list(@AuthenticationPrincipal CurrentUser user) {
        return notificationService.listFor(user.id());
    }

    @GetMapping("/unread-count")
    public UnreadCountResponse unreadCount(@AuthenticationPrincipal CurrentUser user) {
        return new UnreadCountResponse(notificationService.unreadCount(user.id()));
    }

    /** 200 with the updated notification, 404 when it is not the caller's. */
    @PostMapping("/{id}/read")
    public NotificationResponse markRead(@AuthenticationPrincipal CurrentUser user,
                                         @PathVariable("id") String id) {
        return notificationService.markRead(user.id(), id);
    }
}
