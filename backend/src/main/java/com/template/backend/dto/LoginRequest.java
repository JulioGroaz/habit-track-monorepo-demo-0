package com.template.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Login payload for email/password authentication.
 */
public record LoginRequest(
    @Email @NotBlank String email,
    @NotBlank @Size(min = 8, max = 72) String password) {
}
