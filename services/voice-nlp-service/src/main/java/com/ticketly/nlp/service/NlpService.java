package com.ticketly.nlp.service;

import com.ticketly.common.dto.nlp.ParseRequest;
import com.ticketly.common.dto.nlp.ParsedQueryResponse;
import com.ticketly.common.web.ApiException;
import com.ticketly.nlp.parser.ParsedQuery;
import com.ticketly.nlp.parser.QueryParser;
import com.ticketly.nlp.stt.SttProvider;
import org.springframework.stereotype.Service;

import java.util.Base64;
import java.util.UUID;

/**
 * Orchestrates one parse request: validation → transcript (STT when audio was
 * sent) → rule-based parsing → {@link ParsedQueryResponse}.
 */
@Service
public class NlpService {

    private final SttProvider sttProvider;
    private final QueryParser parser;

    public NlpService(SttProvider sttProvider, QueryParser parser) {
        this.sttProvider = sttProvider;
        this.parser = parser;
    }

    public ParsedQueryResponse parse(ParseRequest request) {
        if (request == null) {
            throw ApiException.badRequest("Request body is required");
        }
        boolean hasText = request.hasText();
        boolean hasAudio = request.hasAudio();
        if (hasText == hasAudio) {
            throw ApiException.badRequest(
                    "Exactly one of 'text' or 'audioBase64' must be provided");
        }

        String sessionId = (request.sessionId() == null || request.sessionId().isBlank())
                ? UUID.randomUUID().toString()
                : request.sessionId().trim();

        String transcript;
        if (hasAudio) {
            byte[] audio = decodeAudio(request.audioBase64());
            transcript = sttProvider.transcribe(audio, request.contentType());
            if (transcript == null || transcript.isBlank()) {
                throw ApiException.badRequest("Audio could not be transcribed – send text instead");
            }
            transcript = transcript.trim();
        } else {
            transcript = request.text().trim();
        }

        ParsedQuery parsed = parser.parse(transcript);
        return new ParsedQueryResponse(
                sessionId,
                hasText ? request.text() : null,
                transcript,
                parsed.intent(),
                parsed.source(),
                parsed.destination(),
                parsed.transportType(),
                parsed.travelDate(),
                parsed.budgetLimit(),
                parsed.priority().name(),
                parsed.confidence(),
                parsed.detectedTerms());
    }

    private static byte[] decodeAudio(String audioBase64) {
        try {
            return Base64.getDecoder().decode(audioBase64);
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest("audioBase64 is not valid Base64");
        }
    }
}
