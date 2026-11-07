package com.ticketly.gateway.filter;

import com.ticketly.common.security.JwtService;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Set;

/**
 * Rejects unauthenticated requests to protected routes before they reach a downstream service.
 * Public routes (anonymous search, auth, health) pass straight through.
 */
@Component
public class JwtAuthGlobalFilter implements GlobalFilter, Ordered {

    private static final AntPathMatcher MATCHER = new AntPathMatcher();

    /** Routes that never require a token. */
    private static final List<String> PUBLIC_PATTERNS = List.of(
            "/actuator/**",
            "/api/v1/auth/**",
            "/api/v1/nlp/**",
            "/api/v1/search/**",
            "/api/v1/offers/**");

    private final JwtService jwtService;
    private final boolean enabled;
    private final Set<String> extraPublicPaths;

    public JwtAuthGlobalFilter(JwtService jwtService,
                               @Value("${gateway.security.enabled:true}") boolean enabled,
                               @Value("${gateway.security.public-paths:}") String extraPublicPaths) {
        this.jwtService = jwtService;
        this.enabled = enabled;
        this.extraPublicPaths = Set.of(extraPublicPaths.isBlank()
                ? new String[0]
                : extraPublicPaths.split(","));
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        if (!enabled) {
            return chain.filter(exchange);
        }
        String path = exchange.getRequest().getPath().value();
        if (isPublic(path)) {
            return chain.filter(exchange);
        }

        String authorization = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return unauthorized(exchange, "Missing bearer token");
        }
        try {
            Claims claims = jwtService.parse(authorization.substring(7).trim());
            ServerHttpRequest mutated = exchange.getRequest().mutate()
                    .header("X-User-Id", claims.getSubject())
                    .header("X-User-Name", String.valueOf(claims.get("name")))
                    .build();
            return chain.filter(exchange.mutate().request(mutated).build());
        } catch (Exception ex) {
            return unauthorized(exchange, "Invalid or expired token");
        }
    }

    private boolean isPublic(String path) {
        if (extraPublicPaths.contains(path)) {
            return true;
        }
        for (String pattern : PUBLIC_PATTERNS) {
            if (MATCHER.match(pattern, path)) {
                return true;
            }
        }
        return false;
    }

    private Mono<Void> unauthorized(ServerWebExchange exchange, String message) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        String body = "{\"status\":401,\"code\":\"unauthorized\",\"message\":\"" + message + "\"}";
        DataBuffer buffer = response.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8));
        return response.writeWith(Mono.just(buffer));
    }

    @Override
    public int getOrder() {
        return -50;
    }
}
