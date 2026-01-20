package com.template.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Registration payload for creating a new user account. */
public record RegisterRequest(
    @Email @NotBlank String email, @NotBlank @Size(min = 8, max = 72) String password) {}
