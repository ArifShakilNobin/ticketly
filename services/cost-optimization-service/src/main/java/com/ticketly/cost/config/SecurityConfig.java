package com.ticketly.cost.config;

import com.ticketly.common.security.JwtAuthenticationFilter;
import com.ticketly.common.security.JsonAuthenticationEntryPoint;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Stateless JWT security. The pricing endpoints are called server-to-server by the aggregator and
 * the booking service, so they are permitted without a user token (see the Javadoc on
 * {@link com.ticketly.cost.api.OptimizeController}).
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
                                                   JwtAuthenticationFilter jwtAuthenticationFilter,
                                                   JsonAuthenticationEntryPoint entryPoint) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/optimize", "/api/v1/offers/**", "/actuator/**").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(handler -> handler.authenticationEntryPoint(entryPoint))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
