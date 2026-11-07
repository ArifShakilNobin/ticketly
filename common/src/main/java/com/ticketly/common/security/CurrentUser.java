package com.ticketly.common.security;

import java.security.Principal;

/**
 * Authenticated caller. Stored as the principal of the Spring Security context.
 */
public record CurrentUser(String id, String name, String phone, String email) implements Principal {

    @Override
    public String getName() {
        return name == null || name.isBlank() ? id : name;
    }
}
