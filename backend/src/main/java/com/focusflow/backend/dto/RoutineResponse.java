package com.focusflow.backend.dto;

import java.time.DayOfWeek;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Responsibility: Represents routine data returned by the API. Architecture: Response DTO for
 * routine endpoints and sync operations. Why: Keeps the API contract explicit while abstracting the
 * DB bitmask format.
 */
public record RoutineResponse(
    UUID id,
    String title,
    String colorTag,
    List<DayOfWeek> scheduleDays,
    boolean active,
    Instant clientUpdatedAt,
    Instant serverUpdatedAt,
    Instant createdAt,
    Instant updatedAt,
    Instant deletedAt) {}
