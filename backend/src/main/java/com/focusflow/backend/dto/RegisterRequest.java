package com.focusflow.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Responsibility: Captures registration data for a new user. Architecture: DTO for the controller
 * layer to validate inbound auth requests. Why: Decouples API payload validation from the user
 * entity model.
 */
public record RegisterRequest(
    @Email(message = "email must be valid") @NotBlank(message = "email is required") String email,
    @NotBlank(message = "password is required")
        @Size(min = 8, max = 72, message = "password must be 8-72 characters")
        String password) {}
