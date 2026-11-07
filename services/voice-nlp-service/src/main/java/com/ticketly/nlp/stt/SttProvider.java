package com.ticketly.nlp.stt;

/**
 * Speech-to-text abstraction. Implementations must never throw for ordinary
 * client input — they either transcribe or fall back to a deterministic mock.
 */
public interface SttProvider {

    /**
     * @param audio       raw audio bytes
     * @param contentType e.g. {@code audio/wav}, {@code audio/webm}; may be {@code null}
     * @return the transcript (never {@code null})
     */
    String transcribe(byte[] audio, String contentType);
}
