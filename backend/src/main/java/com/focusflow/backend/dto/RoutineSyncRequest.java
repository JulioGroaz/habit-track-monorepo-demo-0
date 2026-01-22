package com.focusflow.backend.dto;

import jakarta.validation.constraints.NotNull;
import java.time.DayOfWeek;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Responsibility: Captures a routine change coming from an offline client. Architecture: Sync DTO
 * used by the sync service to apply or reject changes. Why: Keeps sync input explicit so conflict
 * handling can be deterministic.
 */
public record RoutineSyncRequest(
    @NotNull(message = "id is required") UUID id,
    String title,
    String colorTag,
    List<DayOfWeek> scheduleDays,
    Boolean active,
    @NotNull(message = "clientUpdatedAt is required") Instant clientUpdatedAt,
    Instant deletedAt) {}
