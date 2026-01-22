package com.focusflow.backend.dto;

import com.focusflow.backend.entity.JobApplicationSource;
import com.focusflow.backend.entity.JobApplicationStatus;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Captures a job application change coming from an offline client. Architecture:
 * Sync DTO used to apply or reject job application updates. Why: Keeps sync input explicit so
 * server-side conflict logic remains predictable.
 */
public record JobApplicationSyncRequest(
    @NotNull(message = "id is required") UUID id,
    String company,
    String role,
    String location,
    JobApplicationSource source,
    JobApplicationStatus status,
    LocalDate appliedDate,
    String notes,
    String url,
    @NotNull(message = "clientUpdatedAt is required") Instant clientUpdatedAt,
    Instant deletedAt) {}
