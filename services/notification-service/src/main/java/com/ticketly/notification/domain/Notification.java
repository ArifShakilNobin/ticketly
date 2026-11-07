package com.ticketly.notification.domain;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

/** A delivered (or attempted) notification, stored in the {@code notifications} collection. */
@Document(collection = "notifications")
public class Notification {

    @Id
    private String id;

    @Indexed
    private String userId;

    /** SMS / EMAIL */
    private String channel;

    private String title;

    private String body;

    /** SENT / FAILED */
    private String status;

    /** The booking this notification is about. */
    @Indexed
    private String relatedId;

    private Instant sentAt;

    private boolean read;

    protected Notification() {
    }

    public Notification(String userId, String channel, String title, String body,
                        String status, String relatedId, Instant sentAt) {
        this.userId = userId;
        this.channel = channel;
        this.title = title;
        this.body = body;
        this.status = status;
        this.relatedId = relatedId;
        this.sentAt = sentAt;
    }

    public String getId() {
        return id;
    }

    public String getUserId() {
        return userId;
    }

    public String getChannel() {
        return channel;
    }

    public String getTitle() {
        return title;
    }

    public String getBody() {
        return body;
    }

    public String getStatus() {
        return status;
    }

    public String getRelatedId() {
        return relatedId;
    }

    public Instant getSentAt() {
        return sentAt;
    }

    public boolean isRead() {
        return read;
    }

    public void setRead(boolean read) {
        this.read = read;
    }
}
