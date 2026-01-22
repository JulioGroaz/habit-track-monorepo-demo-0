package com.focusflow.backend.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Captures check-in data for create/update operations. Architecture: DTO validated
 * by controllers before invoking check-in services. Why: Keeps API payloads explicit and isolates
 * persistence concerns.
 */
public record CheckInRequest(
    @NotNull(message = "routineId is required") UUID routineId,
    @NotNull(message = "date is required") LocalDate date,
    @NotNull(message = "completed is required") Boolean completed,
    Instant completedAt,
    Instant clientUpdatedAt) {}
