package com.ticketly.gateway;

import com.ticketly.common.security.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * Edge gateway. Routes traffic to the downstream services, validates JWTs and
 * applies per-client rate limiting.
 *
 * <p>Note: this application deliberately does <b>not</b> component-scan {@code com.ticketly}
 * so that servlet-only beans from the common module are never instantiated here.</p>
 */
@SpringBootApplication
public class ApiGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }

    @Bean
    public JwtService jwtService(@Value("${ticketly.security.jwt.secret}") String secret,
                                 @Value("${ticketly.security.jwt.expiration-ms:86400000}") long expirationMs) {
        return new JwtService(secret, expirationMs);
    }
}
