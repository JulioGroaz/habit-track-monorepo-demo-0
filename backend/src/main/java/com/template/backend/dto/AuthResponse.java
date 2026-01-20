package com.template.backend.dto;

/**
 * Authentication response carrying the issued JWT.
 */
public record AuthResponse(String token) {
}
