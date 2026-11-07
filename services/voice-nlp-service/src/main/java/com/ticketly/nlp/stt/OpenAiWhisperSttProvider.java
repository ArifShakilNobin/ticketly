package com.ticketly.nlp.stt;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.net.http.HttpClient;
import java.time.Duration;

/**
 * Real speech-to-text through OpenAI's Whisper transcription endpoint
 * ({@code voice.stt.provider=openai}). Any failure — blank API key, network
 * problem, error response — degrades to the deterministic
 * {@link MockSttProvider} with a WARN log; it never bubbles up a 500.
 *
 * <p>The mock fallback is constructed directly (rather than injected) because the
 * mock bean only exists when {@code voice.stt.provider=mock}.</p>
 */
@Component
@ConditionalOnProperty(name = "voice.stt.provider", havingValue = "openai")
public class OpenAiWhisperSttProvider implements SttProvider {

    private static final Logger log = LoggerFactory.getLogger(OpenAiWhisperSttProvider.class);

    private final RestClient restClient;
    private final String apiKey;
    private final String transcriptionsUrl;
    private final String model;
    private final MockSttProvider fallback = new MockSttProvider();

    public OpenAiWhisperSttProvider(@Value("${openai.api-key:}") String apiKey,
                                    @Value("${openai.base-url:https://api.openai.com}") String baseUrl,
                                    @Value("${openai.model:whisper-1}") String model) {
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.transcriptionsUrl = trimTrailingSlashes(baseUrl) + "/v1/audio/transcriptions";
        this.model = model;

        JdkClientHttpRequestFactory factory =
                new JdkClientHttpRequestFactory(HttpClient.newBuilder()
                        .connectTimeout(Duration.ofSeconds(5))
                        .build());
        factory.setReadTimeout(Duration.ofSeconds(30));
        this.restClient = RestClient.builder().requestFactory(factory).build();
    }

    @Override
    public String transcribe(byte[] audio, String contentType) {
        if (apiKey.isEmpty()) {
            log.warn("openai.api-key is blank – falling back to mock transcription");
            return fallback.transcribe(audio, contentType);
        }
        if (audio == null || audio.length == 0) {
            log.warn("Empty audio payload – falling back to mock transcription");
            return fallback.transcribe(audio, contentType);
        }
        try {
            MultipartBodyBuilder body = new MultipartBodyBuilder();
            body.part("file", audioResource(audio, contentType), mediaType(contentType));
            body.part("model", model);
            body.part("language", "bn");
            WhisperResponse response = restClient.post()
                    .uri(transcriptionsUrl)
                    .header("Authorization", "Bearer " + apiKey)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body.build())
                    .retrieve()
                    .body(WhisperResponse.class);
            if (response != null && response.text() != null && !response.text().isBlank()) {
                return response.text();
            }
            log.warn("OpenAI transcription returned no text – falling back to mock transcription");
        } catch (Exception ex) {
            log.warn("OpenAI transcription failed ({} – falling back to mock transcription",
                    ex.getMessage());
        }
        return fallback.transcribe(audio, contentType);
    }

    private static ByteArrayResource audioResource(byte[] audio, String contentType) {
        String extension = extension(contentType);
        return new ByteArrayResource(audio) {
            @Override
            public String getFilename() {
                return "voice." + extension;
            }
        };
    }

    private static MediaType mediaType(String contentType) {
        if (contentType == null || contentType.isBlank()) {
            return MediaType.APPLICATION_OCTET_STREAM;
        }
        try {
            return MediaType.parseMediaType(contentType);
        } catch (Exception ex) {
            return MediaType.APPLICATION_OCTET_STREAM;
        }
    }

    private static String extension(String contentType) {
        if (contentType == null) {
            return "bin";
        }
        return switch (contentType.toLowerCase()) {
            case "audio/wav", "audio/x-wav", "audio/wave" -> "wav";
            case "audio/webm" -> "webm";
            case "audio/mpeg", "audio/mp3" -> "mp3";
            case "audio/ogg", "application/ogg" -> "ogg";
            case "audio/mp4", "audio/m4a", "audio/x-m4a" -> "m4a";
            default -> "bin";
        };
    }

    private static String trimTrailingSlashes(String value) {
        String result = value == null ? "" : value.trim();
        while (result.endsWith("/")) {
            result = result.substring(0, result.length() - 1);
        }
        return result.isEmpty() ? "https://api.openai.com" : result;
    }

    /** Response shape of {@code /v1/audio/transcriptions}. */
    public record WhisperResponse(String text) {
    }
}
