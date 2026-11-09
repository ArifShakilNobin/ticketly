package com.ticketly.aggregator.cache;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ticketly.common.dto.search.SearchRequest;
import com.ticketly.common.dto.search.SearchResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Locale;
import java.util.Optional;

/**
 * Redis-backed fare cache. Every failure (Redis down, serialisation error) is
 * swallowed so that a cache problem degrades performance, never correctness.
 */
@Component
public class SearchCache {

    private static final Logger log = LoggerFactory.getLogger(SearchCache.class);
    private static final String PREFIX = "ticketly:search:";

    private final StringRedisTemplate redis;
    private final ObjectMapper mapper;
    private final Duration ttl;

    public SearchCache(StringRedisTemplate redis,
                       ObjectMapper mapper,
                       @Value("${aggregator.cache.ttl-seconds:60}") long ttlSeconds) {
        this.redis = redis;
        this.mapper = mapper;
        this.ttl = Duration.ofSeconds(Math.max(1, ttlSeconds));
    }

    /**
     * Cache key covering everything that changes the answer: route, date, mode,
     * ranking preference and budget.
     */
    public static String key(SearchRequest request) {
        String budget = request.budgetLimit() == null ? "-" : request.budgetLimit().stripTrailingZeros().toPlainString();
        return PREFIX + norm(request.source())
                + ":" + norm(request.destination())
                + ":" + request.safeTravelDate()
                + ":" + request.safeTransportType()
                + ":" + request.safePriority()
                + ":" + budget;
    }

    private static String norm(String value) {
        if (value == null) {
            return "-";
        }
        return value.trim().toLowerCase(Locale.ROOT).replaceAll("\\s+", " ");
    }

    public Optional<SearchResponse> get(String key) {
        try {
            String json = redis.opsForValue().get(key);
            if (json == null || json.isBlank()) {
                return Optional.empty();
            }
            return Optional.ofNullable(mapper.readValue(json, SearchResponse.class));
        } catch (Exception ex) {
            log.debug("Redis read failed for {}: {}", key, ex.toString());
            return Optional.empty();
        }
    }

    public void put(String key, SearchResponse response) {
        try {
            redis.opsForValue().set(key, mapper.writeValueAsString(response), ttl);
        } catch (JsonProcessingException ex) {
            log.debug("Could not serialise search response for the cache: {}", ex.toString());
        } catch (Exception ex) {
            log.debug("Redis write failed for {}: {}", key, ex.toString());
        }
    }
}
