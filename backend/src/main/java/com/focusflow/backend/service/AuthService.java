package com.focusflow.backend.service;

import com.focusflow.backend.dto.AuthResponse;
import com.focusflow.backend.dto.LoginRequest;
import com.focusflow.backend.dto.RegisterRequest;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.repository.UserRepository;
import com.focusflow.backend.security.JwtService;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Responsibility: Handles user registration and authentication flows. Architecture: Service layer
 * orchestrating repositories and security utilities. Why: Centralizes auth rules (password hashing,
 * token issuance) away from controllers.
 */
@Service
public class AuthService {

  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;

  public AuthService(
      UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
    this.jwtService = jwtService;
  }

  public AuthResponse register(RegisterRequest request) {
    String normalizedEmail = request.email().trim().toLowerCase();
    if (userRepository.existsByEmail(normalizedEmail)) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
    }

    // Hash the password once and store only the hash; never persist raw credentials.
    User user =
        new User(UUID.randomUUID(), normalizedEmail, passwordEncoder.encode(request.password()));
    userRepository.save(user);

    return new AuthResponse(jwtService.generateToken(user), user.getId(), user.getEmail());
  }

  public AuthResponse login(LoginRequest request) {
    User user =
        userRepository
            .findByEmail(request.email().trim().toLowerCase())
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));

    // Use the encoder to avoid timing leaks and keep hash format consistent.
    if (!passwordEncoder.matches(request.password(), user.getPassword())) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
    }

    return new AuthResponse(jwtService.generateToken(user), user.getId(), user.getEmail());
  }
}
