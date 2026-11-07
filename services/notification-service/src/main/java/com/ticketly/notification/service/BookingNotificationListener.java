package com.ticketly.notification.service;

import com.ticketly.common.event.BookingCancelledEvent;
import com.ticketly.common.event.BookingConfirmedEvent;
import com.ticketly.common.event.Topics;
import com.ticketly.notification.domain.Notification;
import com.ticketly.notification.repo.NotificationRepository;
import com.ticketly.notification.sender.NotificationSender;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.time.Instant;

/**
 * Consumes booking events and turns them into persisted notifications.
 *
 * <p>Both listeners wrap their work in try/catch: a failing consumer only logs at ERROR and never
 * kills the listener container, so the partition keeps being processed.</p>
 */
@Component
public class BookingNotificationListener {

    private static final Logger log = LoggerFactory.getLogger(BookingNotificationListener.class);

    private final NotificationRepository notifications;
    private final NotificationSender sender;

    public BookingNotificationListener(NotificationRepository notifications, NotificationSender sender) {
        this.notifications = notifications;
        this.sender = sender;
    }

    @KafkaListener(topics = Topics.BOOKING_CONFIRMED)
    public void onBookingConfirmed(BookingConfirmedEvent event) {
        try {
            NotificationMessageFactory.Composed message = NotificationMessageFactory.confirmed(event);
            deliver(event.userId(), message, event.bookingId());
        } catch (Exception ex) {
            log.error("Failed to process booking.confirmed event for booking {}",
                    event == null ? null : event.bookingId(), ex);
        }
    }

    @KafkaListener(topics = Topics.BOOKING_CANCELLED)
    public void onBookingCancelled(BookingCancelledEvent event) {
        try {
            NotificationMessageFactory.Composed message = NotificationMessageFactory.cancelled(event);
            deliver(event.userId(), message, event.bookingId());
        } catch (Exception ex) {
            log.error("Failed to process booking.cancelled event for booking {}",
                    event == null ? null : event.bookingId(), ex);
        }
    }

    private void deliver(String userId, NotificationMessageFactory.Composed message, String relatedId) {
        String status = sender.send(userId, message.title(), message.body());
        Notification notification = new Notification(
                userId, message.channel(), message.title(), message.body(),
                status, relatedId, Instant.now());
        notifications.save(notification);
        log.info("Stored {} notification for {} (relatedId={}, status={})",
                message.channel(), userId, relatedId, status);
    }
}
