package com.focusflow.backend.dto;

import java.util.UUID;

/**
 * Responsibility: Exposes a safe subset of user profile data. Architecture: API response DTO for
 * identity-related endpoints. Why: Prevents leaking sensitive fields while still giving clients a
 * stable identifier.
 */
public record UserResponse(UUID id, String email) {}
