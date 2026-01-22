package com.focusflow.backend.dto;

import java.util.UUID;

/**
 * Responsibility: Returns JWT and user identity data after successful authentication. Architecture:
 * API response DTO for auth endpoints. Why: Gives clients the token and identity info they need
 * without exposing sensitive fields.
 */
public record AuthResponse(String token, UUID userId, String email) {}
