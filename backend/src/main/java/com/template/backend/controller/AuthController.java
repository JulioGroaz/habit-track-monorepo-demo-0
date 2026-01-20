package com.template.backend.controller;

import com.template.backend.dto.AuthResponse;
import com.template.backend.dto.LoginRequest;
import com.template.backend.dto.RegisterRequest;
import com.template.backend.dto.UserResponse;
import com.template.backend.entity.User;
import com.template.backend.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Authentication endpoints: register, login, and the current authenticated user.
 */
@RestController
@RequestMapping("/api")
public class AuthController {

  private final AuthService authService;

  public AuthController(AuthService authService) {
    this.authService = authService;
  }

  /**
   * Registers a new user and returns a JWT for immediate use.
   */
  @PostMapping("/auth/register")
  public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
    return authService.register(request);
  }

  /**
   * Authenticates a user and returns a JWT if credentials are valid.
   */
  @PostMapping("/auth/login")
  public AuthResponse login(@Valid @RequestBody LoginRequest request) {
    return authService.login(request);
  }

  /**
   * Returns the authenticated user's public profile.
   */
  @GetMapping("/me")
  public UserResponse me(@AuthenticationPrincipal User user) {
    return new UserResponse(user.getId(), user.getEmail());
  }
}
