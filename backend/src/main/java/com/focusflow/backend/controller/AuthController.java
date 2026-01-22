package com.focusflow.backend.controller;

import com.focusflow.backend.dto.AuthResponse;
import com.focusflow.backend.dto.LoginRequest;
import com.focusflow.backend.dto.RegisterRequest;
import com.focusflow.backend.dto.UserResponse;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Responsibility: Exposes authentication endpoints for registration and login. Architecture: API
 * layer controller delegating auth workflows to services. Why: Keeps auth routes thin and
 * consistently documented with Swagger.
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Auth")
public class AuthController {

  private final AuthService authService;

  public AuthController(AuthService authService) {
    this.authService = authService;
  }

  @PostMapping("/register")
  @Operation(summary = "Register", description = "Registers a user and returns a JWT.")
  @ApiResponse(responseCode = "200", description = "User registered")
  @ApiResponse(responseCode = "409", description = "Email already registered")
  public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
    return authService.register(request);
  }

  @PostMapping("/login")
  @Operation(summary = "Login", description = "Authenticates a user and returns a JWT.")
  @ApiResponse(responseCode = "200", description = "User authenticated")
  @ApiResponse(responseCode = "401", description = "Invalid credentials")
  public AuthResponse login(@Valid @RequestBody LoginRequest request) {
    return authService.login(request);
  }

  @GetMapping("/me")
  @Operation(summary = "Get current user", description = "Returns the authenticated user profile.")
  @ApiResponse(responseCode = "200", description = "User profile returned")
  public UserResponse me(@AuthenticationPrincipal User user) {
    return new UserResponse(user.getId(), user.getEmail());
  }
}
