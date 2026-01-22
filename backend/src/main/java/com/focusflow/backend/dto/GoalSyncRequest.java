package com.focusflow.backend.dto;

import com.focusflow.backend.entity.GoalStatus;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Captures a goal change coming from an offline client. Architecture: Sync DTO
 * consumed by the sync service for conflict resolution. Why: Allows the server to compare client
 * timestamps without trusting user identifiers.
 */
public record GoalSyncRequest(
    @NotNull(message = "id is required") UUID id,
    String title,
    String description,
    LocalDate targetDate,
    GoalStatus status,
    Instant completedAt,
    @NotNull(message = "clientUpdatedAt is required") Instant clientUpdatedAt,
    Instant deletedAt) {}
