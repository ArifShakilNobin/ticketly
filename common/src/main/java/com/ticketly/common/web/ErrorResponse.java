package com.ticketly.common.web;

import java.time.Instant;
import java.util.Map;

/** Uniform error envelope returned by every Ticketly service. */
public record ErrorResponse(int status, String code, String message, Map<String, String> details, Instant timestamp) {

    public static ErrorResponse of(int status, String code, String message) {
        return new ErrorResponse(status, code, message, null, Instant.now());
    }

    public static ErrorResponse of(int status, String code, String message, Map<String, String> details) {
        return new ErrorResponse(status, code, message, details, Instant.now());
    }
}
