package com.ticketly.nlp.service;

import com.ticketly.common.dto.SearchPriority;
import com.ticketly.common.dto.nlp.ParseRequest;
import com.ticketly.common.dto.nlp.ParsedQueryResponse;
import com.ticketly.common.web.ApiException;
import com.ticketly.nlp.parser.QueryParser;
import com.ticketly.nlp.stt.MockSttProvider;
import org.junit.jupiter.api.Test;

import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** Plain JUnit tests for the parse orchestration — no Spring context. */
class NlpServiceTest {

    private final MockSttProvider stt = new MockSttProvider();
    private final NlpService service = new NlpService(stt, new QueryParser());

    @Test
    void rejectsBothTextAndAudio() {
        ApiException ex = assertThrows(ApiException.class, () -> service.parse(
                new ParseRequest("ঢাকা থেকে খুলনা", "YWJjZg==", "audio/wav", null)));
        assertEquals(400, ex.getStatus());
    }

    @Test
    void rejectsNeitherTextNorAudio() {
        ApiException ex = assertThrows(ApiException.class,
                () -> service.parse(new ParseRequest(null, null, null, null)));
        assertEquals(400, ex.getStatus());

        ex = assertThrows(ApiException.class,
                () -> service.parse(new ParseRequest("   ", "  ", "audio/wav", null)));
        assertEquals(400, ex.getStatus());
    }

    @Test
    void rejectsInvalidBase64Audio() {
        ApiException ex = assertThrows(ApiException.class, () -> service.parse(
                new ParseRequest(null, "%%%not-base64%%%", "audio/wav", null)));
        assertEquals(400, ex.getStatus());
    }

    @Test
    void generatesSessionIdWhenMissing() {
        ParsedQueryResponse response = service.parse(
                new ParseRequest("ঢাকা থেকে খুলনা ট্রেন", null, null, null));

        assertNotNull(response.sessionId());
        assertFalse(response.sessionId().isBlank());
        assertEquals("ঢাকা", response.source());
        assertEquals("খুলনা", response.destination());
        assertEquals("ঢাকা থেকে খুলনা ট্রেন", response.text());
        assertEquals(response.text(), response.transcript());
        assertEquals(SearchPriority.BALANCED.name(), response.priority());
    }

    @Test
    void keepsProvidedSessionId() {
        ParsedQueryResponse response = service.parse(
                new ParseRequest("kal dhaka theke ctg bus", null, null, "session-42"));
        assertEquals("session-42", response.sessionId());
        assertEquals("Dhaka", response.source());
        assertEquals("CTG", response.destination());
    }

    @Test
    void audioRequestGoesThroughSttAndLeavesTextNull() {
        String audio = Base64.getEncoder().encodeToString(new byte[]{1, 2, 3, 4});
        ParsedQueryResponse response = service.parse(
                new ParseRequest(null, audio, "audio/wav", "s-1"));

        assertEquals("s-1", response.sessionId());
        assertNull(response.text());
        assertEquals(MockSttProvider.DEMO_TRANSCRIPT, response.transcript());
        // the deterministic demo transcript parses to a real route
        assertEquals("ঢাকা", response.source());
        assertEquals("খুলনা", response.destination());
        assertEquals(SearchPriority.CHEAPEST.name(), response.priority());
        assertNotNull(response.travelDate());
        assertTrue(response.confidence() > 0.5);
    }
}
