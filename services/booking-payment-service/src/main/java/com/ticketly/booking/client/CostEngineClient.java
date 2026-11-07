package com.ticketly.booking.client;

import com.ticketly.common.dto.cost.OptimizeRequest;
import com.ticketly.common.dto.cost.OptimizeResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Server-to-server client for the cost-optimization-service pricing engine
 * ({@code POST /api/v1/optimize} — public, network isolated inside Docker).
 */
@Component
public class CostEngineClient {

    private static final Logger log = LoggerFactory.getLogger(CostEngineClient.class);

    private final RestClient restClient;

    public CostEngineClient(@Value("${cost-service.url:http://localhost:8084}") String baseUrl) {
        this.restClient = RestClient.builder().baseUrl(baseUrl).build();
    }

    /** Calls the pricing engine; throws when it is unreachable — callers decide on a fallback. */
    public OptimizeResponse optimize(OptimizeRequest request) {
        OptimizeResponse response = restClient.post()
                .uri("/api/v1/optimize")
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(OptimizeResponse.class);
        if (log.isDebugEnabled()) {
            log.debug("Cost engine responded for {} fare(s)", request.items() == null ? 0 : request.items().size());
        }
        return response;
    }
}
