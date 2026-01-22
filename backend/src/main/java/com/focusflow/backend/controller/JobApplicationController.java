package com.focusflow.backend.controller;

import com.focusflow.backend.dto.JobApplicationRequest;
import com.focusflow.backend.dto.JobApplicationResponse;
import com.focusflow.backend.entity.JobApplicationSource;
import com.focusflow.backend.entity.JobApplicationStatus;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.JobApplicationMapper;
import com.focusflow.backend.service.JobApplicationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Responsibility: Exposes CRUD endpoints for job applications. Architecture: API layer controller
 * delegating to application services. Why: Keeps HTTP handling thin and ensures user scoping is
 * enforced in services.
 */
@RestController
@RequestMapping("/api/v1/applications")
@Tag(name = "Job Applications")
public class JobApplicationController {

  private final JobApplicationService jobApplicationService;
  private final JobApplicationMapper jobApplicationMapper;

  public JobApplicationController(
      JobApplicationService jobApplicationService, JobApplicationMapper jobApplicationMapper) {
    this.jobApplicationService = jobApplicationService;
    this.jobApplicationMapper = jobApplicationMapper;
  }

  @GetMapping
  @Operation(
      summary = "List job applications",
      description = "Lists job applications with optional filtering.")
  @ApiResponse(responseCode = "200", description = "Job applications returned")
  public Page<JobApplicationResponse> list(
      @AuthenticationPrincipal User user,
      @Parameter(description = "Filter by status") @RequestParam(required = false)
          JobApplicationStatus status,
      @Parameter(description = "Filter by source") @RequestParam(required = false)
          JobApplicationSource source,
      @ParameterObject Pageable pageable) {
    return jobApplicationService
        .listApplications(user, status, source, pageable)
        .map(jobApplicationMapper::toResponse);
  }

  @PostMapping
  @Operation(summary = "Create job application", description = "Creates a job application.")
  @ApiResponse(responseCode = "200", description = "Job application created")
  public JobApplicationResponse create(
      @AuthenticationPrincipal User user, @Valid @RequestBody JobApplicationRequest request) {
    return jobApplicationMapper.toResponse(jobApplicationService.createApplication(user, request));
  }

  @PutMapping("/{id}")
  @Operation(summary = "Update job application", description = "Updates a job application.")
  @ApiResponse(responseCode = "200", description = "Job application updated")
  public JobApplicationResponse update(
      @AuthenticationPrincipal User user,
      @PathVariable UUID id,
      @Valid @RequestBody JobApplicationRequest request) {
    return jobApplicationMapper.toResponse(
        jobApplicationService.updateApplication(user, id, request));
  }

  @DeleteMapping("/{id}")
  @Operation(summary = "Delete job application", description = "Soft deletes a job application.")
  @ApiResponse(responseCode = "204", description = "Job application deleted")
  public ResponseEntity<Void> delete(@AuthenticationPrincipal User user, @PathVariable UUID id) {
    jobApplicationService.deleteApplication(user, id);
    return ResponseEntity.noContent().build();
  }
}
