package com.focusflow.backend.dto;

import com.focusflow.backend.entity.JobApplicationSource;
import com.focusflow.backend.entity.JobApplicationStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Represents job application data returned by the API. Architecture: Response DTO
 * for job application endpoints and sync operations. Why: Delivers sync metadata and status info
 * without exposing persistence internals.
 */
public record JobApplicationResponse(
    UUID id,
    String company,
    String role,
    String location,
    JobApplicationSource source,
    JobApplicationStatus status,
    LocalDate appliedDate,
    String notes,
    String url,
    Instant clientUpdatedAt,
    Instant serverUpdatedAt,
    Instant createdAt,
    Instant updatedAt,
    Instant deletedAt) {}
