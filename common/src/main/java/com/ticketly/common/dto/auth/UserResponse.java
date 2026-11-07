package com.ticketly.common.dto.auth;

import java.time.Instant;

public record UserResponse(String id, String name, String phone, String email, Instant createdAt) {
}
