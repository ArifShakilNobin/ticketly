package com.ticketly.common.security;

import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Servlet-only security support shared by every blocking service.
 * Guarded by {@code @ConditionalOnClass} so that reactive services that depend on
 * this module never try to create servlet beans.
 */
@Configuration
@ConditionalOnClass(name = "jakarta.servlet.http.HttpServletRequest")
public class ServletSecuritySupport {

    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter(JwtService jwtService) {
        return new JwtAuthenticationFilter(jwtService);
    }

    @Bean
    public JsonAuthenticationEntryPoint authenticationEntryPoint() {
        return new JsonAuthenticationEntryPoint();
    }
}
