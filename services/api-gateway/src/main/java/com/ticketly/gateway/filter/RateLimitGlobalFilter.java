package com.ticketly.gateway.filter;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory token-bucket rate limiter keyed by client IP.
 * Deliberately dependency-free so the gateway still works when Redis is down.
 */
@Component
public class RateLimitGlobalFilter implements GlobalFilter, Ordered {

    private final boolean enabled;
    private final double burstCapacity;
    private final double refillPerMinute;
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    public RateLimitGlobalFilter(@Value("${gateway.rate-limit.enabled:true}") boolean enabled,
                                 @Value("${gateway.rate-limit.burst-capacity:100}") double burstCapacity,
                                 @Value("${gateway.rate-limit.refill-per-minute:120}") double refillPerMinute) {
        this.enabled = enabled;
        this.burstCapacity = burstCapacity;
        this.refillPerMinute = refillPerMinute;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        if (!enabled) {
            return chain.filter(exchange);
        }
        if (buckets.size() > 50_000) {
            buckets.clear();
        }
        String key = clientKey(exchange);
        Bucket bucket = buckets.computeIfAbsent(key, k -> new Bucket(burstCapacity));
        if (!bucket.tryConsume(refillPerMinute)) {
            ServerHttpResponse response = exchange.getResponse();
            response.setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
            response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
            response.getHeaders().set("Retry-After", "1");
            String body = "{\"status\":429,\"code\":\"rate_limited\","
                    + "\"message\":\"Too many requests, please slow down\"}";
            DataBuffer buffer = response.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8));
            return response.writeWith(Mono.just(buffer));
        }
        return chain.filter(exchange);
    }

    private static String clientKey(ServerWebExchange exchange) {
        InetSocketAddress remote = exchange.getRequest().getRemoteAddress();
        return remote == null || remote.getAddress() == null ? "unknown" : remote.getAddress().getHostAddress();
    }

    @Override
    public int getOrder() {
        return -100;
    }

    private static final class Bucket {
        private final double capacity;
        private double tokens;
        private long lastRefillNanos;

        private Bucket(double capacity) {
            this.capacity = capacity;
            this.tokens = capacity;
            this.lastRefillNanos = System.nanoTime();
        }

        private synchronized boolean tryConsume(double refillPerMinute) {
            long now = System.nanoTime();
            double elapsedMinutes = (now - lastRefillNanos) / 60_000_000_000.0;
            if (elapsedMinutes > 0) {
                tokens = Math.min(capacity, tokens + elapsedMinutes * refillPerMinute);
                lastRefillNanos = now;
            }
            if (tokens >= 1) {
                tokens -= 1;
                return true;
            }
            return false;
        }
    }
}
