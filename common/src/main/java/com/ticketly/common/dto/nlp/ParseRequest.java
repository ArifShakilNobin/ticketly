package com.ticketly.common.dto.nlp;

/**
 * Either {@code text} or {@code audioBase64} must be provided.
 * {@code contentType} describes the audio (e.g. {@code audio/wav}, {@code audio/webm}).
 */
public record ParseRequest(String text, String audioBase64, String contentType, String sessionId) {

    public boolean hasText() {
        return text != null && !text.isBlank();
    }

    public boolean hasAudio() {
        return audioBase64 != null && !audioBase64.isBlank();
    }
}
