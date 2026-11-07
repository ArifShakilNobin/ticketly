package com.ticketly.gateway.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.reactive.error.ErrorWebExceptionHandler;
import org.springframework.cloud.gateway.support.NotFoundException;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.net.ConnectException;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeoutException;

/**
 * Replaces the default Spring error handler so that a dead or slow downstream
 * service produces a clean JSON error instead of an opaque 500.
 *
 * <p>{@code @Order(-2)} puts it in front of Boot's {@code DefaultErrorWebExceptionHandler (-1)}.</p>
 */
@Component
@Order(-2)
public class JsonErrorWebExceptionHandler implements ErrorWebExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(JsonErrorWebExceptionHandler.class);

    private final ObjectMapper mapper = new ObjectMapper();

    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        ServerHttpResponse response = exchange.getResponse();
        if (response.isCommitted()) {
            return Mono.error(ex);
        }

        HttpStatus status = resolveStatus(ex);
        String code;
        String message;
        switch (status) {
            case GATEWAY_TIMEOUT -> {
                code = "gateway_timeout";
                message = "The upstream service timed out";
            }
            case NOT_FOUND -> {
                code = "not_found";
                message = "No route matched this request";
            }
            case INTERNAL_SERVER_ERROR -> {
                code = "internal_error";
                message = "Unexpected gateway error";
            }
            default -> {
                code = "bad_gateway";
                message = "An upstream service is unavailable";
            }
        }

        if (status == HttpStatus.INTERNAL_SERVER_ERROR) {
            log.error("Unhandled gateway error on {}", exchange.getRequest().getPath().value(), ex);
        } else {
            log.warn("Gateway {} on {}: {}", status.value(),
                    exchange.getRequest().getPath().value(), ex.toString());
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", status.value());
        body.put("code", code);
        body.put("message", message);
        body.put("path", exchange.getRequest().getPath().value());

        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        byte[] bytes;
        try {
            bytes = mapper.writeValueAsBytes(body);
        } catch (Exception serialisationFailure) {
            bytes = ("{\"status\":" + status.value() + ",\"message\":\"" + message + "\"}")
                    .getBytes(StandardCharsets.UTF_8);
        }
        DataBuffer buffer = response.bufferFactory().wrap(bytes);
        return response.writeWith(Mono.just(buffer));
    }

    private static HttpStatus resolveStatus(Throwable ex) {
        Throwable current = ex;
        int depth = 0;
        while (current != null && depth++ < 20) {
            if (current instanceof TimeoutException) {
                return HttpStatus.GATEWAY_TIMEOUT;
            }
            if (current instanceof ConnectException || current instanceof UnknownHostException) {
                return HttpStatus.BAD_GATEWAY;
            }
            if (current instanceof NotFoundException) {
                return HttpStatus.NOT_FOUND;
            }
            current = current.getCause();
        }
        return HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
