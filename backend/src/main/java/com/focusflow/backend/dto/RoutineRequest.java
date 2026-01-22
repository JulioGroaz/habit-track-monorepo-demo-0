package com.focusflow.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.DayOfWeek;
import java.time.Instant;
import java.util.List;

/**
 * Responsibility: Captures routine data for create/update operations. Architecture: DTO used by
 * controllers for validation before hitting services. Why: Separates API concerns from persistence
 * while enforcing schedule requirements.
 */
public record RoutineRequest(
    @NotBlank(message = "title is required")
        @Size(max = 120, message = "title must be at most 120 characters")
        String title,
    @Size(max = 30, message = "colorTag must be at most 30 characters") String colorTag,
    @NotEmpty(message = "scheduleDays is required") List<DayOfWeek> scheduleDays,
    @NotNull(message = "active is required") Boolean active,
    Instant clientUpdatedAt) {}
