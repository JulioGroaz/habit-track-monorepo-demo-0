package com.focusflow.backend.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Represents check-in data returned by the API. Architecture: Response DTO for
 * check-in CRUD and sync endpoints. Why: Exposes routine linkage and sync metadata without
 * embedding full entities.
 */
public record CheckInResponse(
    UUID id,
    UUID routineId,
    LocalDate date,
    boolean completed,
    Instant completedAt,
    Instant clientUpdatedAt,
    Instant serverUpdatedAt,
    Instant createdAt,
    Instant updatedAt,
    Instant deletedAt) {}
