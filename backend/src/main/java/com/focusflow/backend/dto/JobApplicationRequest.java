package com.focusflow.backend.dto;

import com.focusflow.backend.entity.JobApplicationSource;
import com.focusflow.backend.entity.JobApplicationStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import org.hibernate.validator.constraints.URL;

/**
 * Responsibility: Captures job application data for create/update operations. Architecture: DTO
 * validated at the controller boundary. Why: Keeps validation logic aligned with API needs rather
 * than persistence layout.
 */
public record JobApplicationRequest(
    @NotBlank(message = "company is required")
        @Size(max = 200, message = "company must be at most 200 characters")
        String company,
    @NotBlank(message = "role is required")
        @Size(max = 200, message = "role must be at most 200 characters")
        String role,
    @Size(max = 200, message = "location must be at most 200 characters") String location,
    @NotNull(message = "source is required") JobApplicationSource source,
    @NotNull(message = "status is required") JobApplicationStatus status,
    LocalDate appliedDate,
    @Size(max = 4000, message = "notes must be at most 4000 characters") String notes,
    @URL(message = "url must be valid")
        @Size(max = 500, message = "url must be at most 500 characters")
        String url,
    Instant clientUpdatedAt) {}
