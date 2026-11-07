package com.ticketly.common.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * Issues and validates the shared HS256 JWT used by every Ticketly service.
 * The secret is supplied through {@code ticketly.security.jwt.secret} (env var {@code JWT_SECRET}).
 */
@Component
public class JwtService {

    private final SecretKey key;
    private final long expirationMs;

    public JwtService(@Value("${ticketly.security.jwt.secret}") String secret,
                      @Value("${ticketly.security.jwt.expiration-ms:86400000}") long expirationMs) {
        if (secret == null || secret.length() < 32) {
            throw new IllegalStateException("ticketly.security.jwt.secret must be at least 32 characters long");
        }
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    public String issue(String userId, String name, String phone, String email) {
        Date now = new Date();
        Map<String, Object> claims = new HashMap<>();
        claims.put("name", value(name));
        claims.put("phone", value(phone));
        claims.put("email", value(email));
        return Jwts.builder()
                .claims().add(claims).and()
                .subject(userId)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMs))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }

    public boolean isValid(String token) {
        try {
            parse(token);
            return true;
        } catch (Exception ex) {
            return false;
        }
    }

    public CurrentUser toUser(Claims claims) {
        return new CurrentUser(claims.getSubject(),
                claims.get("name", String.class),
                claims.get("phone", String.class),
                claims.get("email", String.class));
    }

    private static String value(String raw) {
        return raw == null ? "" : raw;
    }
}
