package com.ticketly.aggregator.provider;

import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.net.http.HttpClient;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;

/**
 * Generic JSON-over-HTTP client for a transport partner. It POSTs the query to
 * {@code {baseUrl}/search} and expects {@code {"fares": [...]}} back. Any error
 * (unreachable host, 4xx/5xx, malformed body) is thrown to the caller, which
 * then falls back to the deterministic mock.
 */
public class HttpProviderClient implements ProviderClient {

    private static final Logger log = LoggerFactory.getLogger(HttpProviderClient.class);

    private final TransportType type;
    private final String baseUrl;
    private final RestClient restClient;

    public HttpProviderClient(TransportType type, String baseUrl) {
        this.type = type;
        this.baseUrl = baseUrl == null ? "" : baseUrl.trim();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(
                HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(2)).build());
        factory.setReadTimeout(Duration.ofSeconds(4));
        this.restClient = RestClient.builder().requestFactory(factory).build();
    }

    @Override
    public boolean isEnabled() {
        return !baseUrl.isEmpty();
    }

    @Override
    public List<FareItem> fetch(SearchRequest request) {
        String uri = trimTrailingSlashes(baseUrl) + "/search";
        ProviderSearchResult result = restClient.post()
                .uri(uri)
                .body(new ProviderSearchQuery(
                        type,
                        request.source(),
                        request.destination(),
                        request.safeTravelDate()))
                .retrieve()
                .body(ProviderSearchResult.class);
        if (result == null || result.fares() == null) {
            log.warn("{} partner at {} returned an empty body", type, baseUrl);
            return List.of();
        }
        return result.fares();
    }

    private static String trimTrailingSlashes(String value) {
        String result = value;
        while (result.endsWith("/")) {
            result = result.substring(0, result.length() - 1);
        }
        return result;
    }

    /** Query body sent to a partner endpoint. */
    public record ProviderSearchQuery(
            TransportType transportType, String source, String destination, LocalDate travelDate) {
    }

    /** Expected partner response envelope. */
    public record ProviderSearchResult(List<FareItem> fares) {
    }
}
