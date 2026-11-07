package com.ticketly.nlp.stt;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Default {@code voice.stt.provider=mock} implementation. It cannot really decode
 * arbitrary audio, so it always returns the same representative Bengali
 * transcript — deterministic and failure-proof.
 */
@Component
@ConditionalOnProperty(name = "voice.stt.provider", havingValue = "mock", matchIfMissing = true)
public class MockSttProvider implements SttProvider {

    public static final String DEMO_TRANSCRIPT =
            "আগামী শুক্রবার ঢাকা থেকে খুলনার সবচেয়ে কম ভাড়ার টিকিট দেখাও";

    @Override
    public String transcribe(byte[] audio, String contentType) {
        return DEMO_TRANSCRIPT;
    }
}
