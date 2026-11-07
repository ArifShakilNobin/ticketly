package com.ticketly.notification.repo;

import com.ticketly.notification.domain.Notification;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends MongoRepository<Notification, String> {

    /** Newest first, capped at 50 by the caller. */
    List<Notification> findTop50ByUserIdOrderBySentAtDesc(String userId);

    long countByUserIdAndReadFalse(String userId);

    Optional<Notification> findByIdAndUserId(String id, String userId);
}
