package com.focusflow.backend.dto;

import com.focusflow.backend.entity.GoalStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Responsibility: Captures goal data for create/update operations. Architecture: DTO used by the
 * controller layer to validate inbound goal payloads. Why: Keeps validation rules explicit without
 * tying them to persistence concerns.
 */
public record GoalRequest(
    @NotBlank(message = "title is required")
        @Size(max = 120, message = "title must be at most 120 characters")
        String title,
    @Size(max = 2000, message = "description must be at most 2000 characters") String description,
    LocalDate targetDate,
    @NotNull(message = "status is required") GoalStatus status,
    Instant completedAt,
    Instant clientUpdatedAt) {}
