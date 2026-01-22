package com.focusflow.backend.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Captures a check-in change coming from an offline client. Architecture: Sync DTO
 * consumed by check-in sync logic. Why: Makes routine linkage and completion metadata explicit for
 * conflict resolution.
 */
public record CheckInSyncRequest(
    @NotNull(message = "id is required") UUID id,
    UUID routineId,
    LocalDate date,
    Boolean completed,
    Instant completedAt,
    @NotNull(message = "clientUpdatedAt is required") Instant clientUpdatedAt,
    Instant deletedAt) {}
