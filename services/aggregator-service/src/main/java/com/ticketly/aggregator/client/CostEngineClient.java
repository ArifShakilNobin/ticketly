package com.ticketly.aggregator.client;

import com.ticketly.common.dto.cost.OptimizeRequest;
import com.ticketly.common.dto.cost.OptimizeResponse;
import com.ticketly.common.dto.search.FareItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.net.http.HttpClient;
import java.time.Duration;
import java.util.List;

/**
 * Server-to-server call to the cost optimisation engine.
 * Never swallows errors itself — the caller decides whether to degrade.
 */
@Component
public class CostEngineClient {

    private static final Logger log = LoggerFactory.getLogger(CostEngineClient.class);

    private final RestClient restClient;

    public CostEngineClient(@Value("${cost-service.url}") String baseUrl,
                            @Value("${cost-service.connect-timeout-ms:1500}") long connectTimeoutMs,
                            @Value("${cost-service.read-timeout-ms:3000}") long readTimeoutMs) {
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(
                HttpClient.newBuilder().connectTimeout(Duration.ofMillis(connectTimeoutMs)).build());
        factory.setReadTimeout(Duration.ofMillis(readTimeoutMs));
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(factory)
                .build();
    }

    public OptimizeResponse optimize(List<FareItem> items,
                                     List<String> paymentMethods,
                                     String priority,
                                     BigDecimal budgetLimit) {
        OptimizeRequest body = new OptimizeRequest(items, paymentMethods, priority, budgetLimit, null);
        OptimizeResponse response = restClient.post()
                .uri("/api/v1/optimize")
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(OptimizeResponse.class);
        if (response == null) {
            log.warn("Cost engine returned an empty body");
        }
        return response;
    }
}
