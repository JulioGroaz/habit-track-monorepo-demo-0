package com.template.backend.service;

import com.template.backend.dto.AuthResponse;
import com.template.backend.dto.LoginRequest;
import com.template.backend.dto.RegisterRequest;
import com.template.backend.entity.User;
import com.template.backend.repository.UserRepository;
import com.template.backend.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Authentication and registration business logic.
 */
@Service
public class AuthService {

  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;

  public AuthService(
      UserRepository userRepository,
      PasswordEncoder passwordEncoder,
      JwtService jwtService) {
    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
    this.jwtService = jwtService;
  }

  public AuthResponse register(RegisterRequest request) {
    if (userRepository.existsByEmail(request.email())) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
    }

    // Persist user with a hashed password and issue a JWT on success.
    User user = new User(request.email(), passwordEncoder.encode(request.password()));
    userRepository.save(user);

    return new AuthResponse(jwtService.generateToken(user));
  }

  public AuthResponse login(LoginRequest request) {
    User user = userRepository.findByEmail(request.email())
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));

    // Use the encoder to avoid timing leaks and keep hash format consistent.
    if (!passwordEncoder.matches(request.password(), user.getPassword())) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
    }

    return new AuthResponse(jwtService.generateToken(user));
  }
}
