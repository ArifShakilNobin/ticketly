package com.ticketly.nlp.api;

import com.ticketly.common.dto.nlp.ParseRequest;
import com.ticketly.common.dto.nlp.ParsedQueryResponse;
import com.ticketly.nlp.service.NlpService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Public NLP endpoints (routed by the gateway at {@code /api/v1/nlp/**}). */
@RestController
@RequestMapping("/api/v1/nlp")
public class NlpController {

    private final NlpService nlpService;

    public NlpController(NlpService nlpService) {
        this.nlpService = nlpService;
    }

    /** Parses a text or voice query into a structured search query. */
    @PostMapping("/parse")
    public ParsedQueryResponse parse(@RequestBody ParseRequest request) {
        return nlpService.parse(request);
    }
}
