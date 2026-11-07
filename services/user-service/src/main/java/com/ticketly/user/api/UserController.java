package com.ticketly.user.api;

import com.ticketly.common.dto.auth.UserResponse;
import com.ticketly.common.security.CurrentUser;
import com.ticketly.user.service.AuthService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final AuthService authService;

    public UserController(AuthService authService) {
        this.authService = authService;
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal CurrentUser user) {
        return authService.me(user.id());
    }
}
