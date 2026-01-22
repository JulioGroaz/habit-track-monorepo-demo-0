package com.focusflow.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * Responsibility: Captures login credentials for authentication. Architecture: DTO in the API layer
 * for input validation. Why: Keeps authentication payloads explicit and separate from persistence
 * models.
 */
public record LoginRequest(
    @Email(message = "email must be valid") @NotBlank(message = "email is required") String email,
    @NotBlank(message = "password is required") String password) {}
