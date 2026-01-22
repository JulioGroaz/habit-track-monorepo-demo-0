package com.focusflow.backend.dto;

import com.focusflow.backend.entity.GoalStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Represents goal data returned by the API. Architecture: Response DTO emitted by
 * controllers and sync endpoints. Why: Provides clients with sync metadata without exposing
 * internal entity state.
 */
public record GoalResponse(
    UUID id,
    String title,
    String description,
    LocalDate targetDate,
    GoalStatus status,
    Instant completedAt,
    Instant clientUpdatedAt,
    Instant serverUpdatedAt,
    Instant createdAt,
    Instant updatedAt,
    Instant deletedAt) {}
