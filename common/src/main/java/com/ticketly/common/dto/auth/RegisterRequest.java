package com.ticketly.common.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "name is required") String name,
        @NotBlank(message = "phone is required") String phone,
        @Email(message = "email must be valid") String email,
        @NotBlank(message = "password is required") @Size(min = 6, message = "password must be at least 6 characters") String password) {
}
