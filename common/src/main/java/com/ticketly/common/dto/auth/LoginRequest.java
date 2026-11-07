package com.ticketly.common.dto.auth;

import jakarta.validation.constraints.NotBlank;

/** {@code identifier} accepts either the phone number or the e-mail address. */
public record LoginRequest(
        @NotBlank(message = "identifier is required") String identifier,
        @NotBlank(message = "password is required") String password) {
}
