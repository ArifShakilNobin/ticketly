package com.ticketly.user.service;

import com.ticketly.common.dto.auth.AuthResponse;
import com.ticketly.common.dto.auth.LoginRequest;
import com.ticketly.common.dto.auth.RegisterRequest;
import com.ticketly.common.dto.auth.UserResponse;
import com.ticketly.common.security.JwtService;
import com.ticketly.common.web.ApiException;
import com.ticketly.user.domain.User;
import com.ticketly.user.repo.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final long expirationMs;

    public AuthService(UserRepository users,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       @Value("${ticketly.security.jwt.expiration-ms:86400000}") long expirationMs) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.expirationMs = expirationMs;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String phone = normalizePhone(request.phone());
        if (users.existsByPhone(phone)) {
            throw ApiException.conflict("A user with this phone number already exists");
        }
        if (request.email() != null && !request.email().isBlank() && users.existsByEmail(request.email())) {
            throw ApiException.conflict("A user with this e-mail already exists");
        }
        User user = new User(request.name().trim(), phone,
                request.email() == null ? "" : request.email().trim().toLowerCase(),
                passwordEncoder.encode(request.password()));
        users.save(user);
        return token(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String identifier = request.identifier().trim();
        User user = users.findByPhone(identifier)
                .or(() -> users.findByEmail(identifier.toLowerCase()))
                .orElseThrow(() -> ApiException.unauthorized("Invalid credentials"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw ApiException.unauthorized("Invalid credentials");
        }
        return token(user);
    }

    @Transactional(readOnly = true)
    public UserResponse me(String userId) {
        User user = users.findById(userId)
                .orElseThrow(() -> ApiException.notFound("User not found"));
        return toResponse(user);
    }

    private AuthResponse token(User user) {
        String token = jwtService.issue(user.getId(), user.getName(), user.getPhone(), user.getEmail());
        return AuthResponse.bearer(token, expirationMs, toResponse(user));
    }

    private static UserResponse toResponse(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getPhone(), user.getEmail(), user.getCreatedAt());
    }

    private static String normalizePhone(String phone) {
        String value = phone.trim().replace(" ", "").replace("-", "");
        if (value.startsWith("+880")) {
            value = "0" + value.substring(4);
        }
        return value;
    }
}
