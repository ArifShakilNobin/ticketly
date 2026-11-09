package com.ticketly.aggregator.service;

import com.ticketly.aggregator.cache.SearchCache;
import com.ticketly.aggregator.client.CostEngineClient;
import com.ticketly.aggregator.domain.SearchLog;
import com.ticketly.aggregator.provider.ProviderRegistry;
import com.ticketly.aggregator.provider.TransportProvider;
import com.ticketly.common.dto.cost.OptimizeResponse;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.OptimizedFare;
import com.ticketly.common.dto.search.PriceBreakdown;
import com.ticketly.common.dto.search.SearchRequest;
import com.ticketly.common.dto.search.SearchResponse;
import com.ticketly.common.web.ApiException;
import com.ticketly.aggregator.repo.SearchLogRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Search pipeline: normalise → cache lookup → parallel provider fan-out →
 * cost optimisation → cache write → analytics log.
 */
@Service
public class SearchService {

    private static final Logger log = LoggerFactory.getLogger(SearchService.class);

    private final ProviderRegistry providers;
    private final SearchCache cache;
    private final CostEngineClient costEngine;
    private final SearchLogRepository searchLogs;
    private final ExecutorService executor;
    private final long searchTimeoutMs;
    private final BigDecimal fallbackConvenienceFee;

    public SearchService(ProviderRegistry providers,
                         SearchCache cache,
                         CostEngineClient costEngine,
                         SearchLogRepository searchLogs,
                         @Qualifier("searchExecutor") ExecutorService executor,
                         @Value("${aggregator.search-timeout-ms:4000}") long searchTimeoutMs,
                         @Value("${aggregator.fallback-convenience-fee:20}") BigDecimal fallbackConvenienceFee) {
        this.providers = providers;
        this.cache = cache;
        this.costEngine = costEngine;
        this.searchLogs = searchLogs;
        this.executor = executor;
        this.searchTimeoutMs = searchTimeoutMs;
        this.fallbackConvenienceFee = fallbackConvenienceFee;
    }

    public SearchResponse search(SearchRequest rawRequest) {
        long startedAt = System.nanoTime();
        SearchRequest request = normalise(rawRequest);

        String cacheKey = SearchCache.key(request);
        var cached = cache.get(cacheKey);
        if (cached.isPresent()) {
            SearchResponse hit = cached.get();
            SearchResponse response = new SearchResponse(
                    hit.searchId(), hit.source(), hit.destination(), hit.travelDate(),
                    hit.transportType(), hit.items(), true, hit.totalFound(), hit.generatedAt());
            record(response, request, latencyMs(startedAt));
            return response;
        }

        List<FareItem> fares = fanOut(request);
        List<OptimizedFare> optimised = optimise(fares, request);

        SearchResponse response = new SearchResponse(
                UUID.randomUUID().toString(),
                request.source(),
                request.destination(),
                request.safeTravelDate(),
                request.safeTransportType(),
                optimised,
                false,
                fares.size(),
                Instant.now());

        cache.put(cacheKey, response);
        record(response, request, latencyMs(startedAt));
        return response;
    }

    // ------------------------------------------------------------- pipeline steps

    private List<FareItem> fanOut(SearchRequest request) {
        List<TransportProvider> targets = providers.resolve(request.transportType());
        if (targets.isEmpty()) {
            log.warn("No provider configured for {}", request.transportType());
            return List.of();
        }

        List<CompletableFuture<List<FareItem>>> futures = targets.stream()
                .map(provider -> CompletableFuture
                        .supplyAsync(() -> safeSearch(provider, request), executor)
                        .orTimeout(searchTimeoutMs, TimeUnit.MILLISECONDS)
                        .exceptionally(ex -> {
                            log.warn("{} did not answer within {} ms: {}",
                                    provider.name(), searchTimeoutMs, ex.toString());
                            return List.of();
                        }))
                .toList();

        List<FareItem> fares = new ArrayList<>();
        for (CompletableFuture<List<FareItem>> future : futures) {
            fares.addAll(future.join());
        }
        return fares;
    }

    private List<FareItem> safeSearch(TransportProvider provider, SearchRequest request) {
        try {
            List<FareItem> result = provider.search(request);
            return result == null ? List.of() : result;
        } catch (Exception ex) {
            log.warn("{} failed unexpectedly: {}", provider.name(), ex.toString());
            return List.of();
        }
    }

    /** Calls the pricing engine, degrading to base fares when it is unavailable. */
    private List<OptimizedFare> optimise(List<FareItem> fares, SearchRequest request) {
        if (fares.isEmpty()) {
            return List.of();
        }
        try {
            OptimizeResponse response = costEngine.optimize(
                    fares,
                    List.of(),
                    request.safePriority().name(),
                    request.budgetLimit());
            if (response != null && response.items() != null) {
                // An empty list here means the budget filter removed every fare.
                return response.items();
            }
            log.warn("Cost engine answered without items, falling back to base fares");
        } catch (Exception ex) {
            log.warn("Cost engine unreachable ({}), falling back to base fares", ex.toString());
        }
        return baseFares(fares);
    }

    /** Degraded pricing: no offers, the configured convenience fee only. */
    private List<OptimizedFare> baseFares(List<FareItem> fares) {
        List<OptimizedFare> degraded = new ArrayList<>(fares.size());
        for (FareItem fare : fares) {
            BigDecimal base = fare.baseFare() == null ? BigDecimal.ZERO : fare.baseFare();
            BigDecimal fee = fallbackConvenienceFee == null ? BigDecimal.ZERO : fallbackConvenienceFee;
            BigDecimal effective = base.add(fee).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
            PriceBreakdown price = new PriceBreakdown(
                    base.setScale(2, RoundingMode.HALF_UP),
                    BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                    BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                    fee.setScale(2, RoundingMode.HALF_UP),
                    effective,
                    BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP));
            degraded.add(new OptimizedFare(fare, price, List.of(), ""));
        }
        return degraded;
    }

    private void record(SearchResponse response, SearchRequest request, long latencyMs) {
        try {
            searchLogs.save(new SearchLog(
                    response.searchId(),
                    request.sessionId(),
                    response.source(),
                    response.destination(),
                    response.travelDate(),
                    response.transportType().name(),
                    response.items().size(),
                    response.cached(),
                    latencyMs));
        } catch (Exception ex) {
            log.warn("Could not persist the search log: {}", ex.toString());
        }
    }

    // ----------------------------------------------------------------- input

    private static long latencyMs(long startedAtNanos) {
        return TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startedAtNanos);
    }

    /** Trims and canonicalises the route so "dhaka" / "Dhaka" / "  Dhaka " share a cache entry. */
    static SearchRequest normalise(SearchRequest request) {
        if (request == null) {
            throw ApiException.badRequest("A search request body is required");
        }
        String source = clean(request.source(), "source");
        String destination = clean(request.destination(), "destination");
        if (source.equalsIgnoreCase(destination)) {
            throw ApiException.badRequest("source and destination must differ");
        }
        LocalDate date = request.safeTravelDate() == null ? LocalDate.now() : request.safeTravelDate();
        return new SearchRequest(
                source,
                destination,
                date,
                request.safeTransportType(),
                request.budgetLimit(),
                request.safePriority(),
                request.sessionId());
    }

    private static String clean(String value, String field) {
        if (value == null || value.isBlank()) {
            throw ApiException.badRequest(field + " is required");
        }
        String collapsed = value.trim().replaceAll("\\s+", " ");
        // Title-case pure Latin input so the UI renders "Dhaka" rather than "dhaka";
        // Bengali script is left untouched.
        if (collapsed.chars().allMatch(c -> c < 128)) {
            StringBuilder out = new StringBuilder(collapsed.length());
            for (String word : collapsed.split(" ")) {
                if (word.isEmpty()) {
                    continue;
                }
                if (!out.isEmpty()) {
                    out.append(' ');
                }
                out.append(Character.toUpperCase(word.charAt(0)));
                out.append(word.substring(1).toLowerCase(Locale.ROOT));
            }
            return out.toString();
        }
        return collapsed;
    }
}
