package com.ticketly.aggregator.domain;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.time.LocalDate;

/** One executed search, persisted for analytics. Collection {@code search_logs}. */
@Document(collection = "search_logs")
public class SearchLog {

    @Id
    private String id;
    private String searchId;
    private String sessionId;
    private String source;
    private String destination;
    private LocalDate travelDate;
    private String transportType;
    private int resultCount;
    private boolean cached;
    private long latencyMs;
    private Instant createdAt;

    protected SearchLog() {
    }

    public SearchLog(String searchId, String sessionId, String source, String destination,
                     LocalDate travelDate, String transportType, int resultCount,
                     boolean cached, long latencyMs) {
        this.searchId = searchId;
        this.sessionId = sessionId;
        this.source = source;
        this.destination = destination;
        this.travelDate = travelDate;
        this.transportType = transportType;
        this.resultCount = resultCount;
        this.cached = cached;
        this.latencyMs = latencyMs;
        this.createdAt = Instant.now();
    }

    public String getId() {
        return id;
    }

    public String getSearchId() {
        return searchId;
    }

    public String getSessionId() {
        return sessionId;
    }

    public String getSource() {
        return source;
    }

    public String getDestination() {
        return destination;
    }

    public LocalDate getTravelDate() {
        return travelDate;
    }

    public String getTransportType() {
        return transportType;
    }

    public int getResultCount() {
        return resultCount;
    }

    public boolean isCached() {
        return cached;
    }

    public long getLatencyMs() {
        return latencyMs;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
