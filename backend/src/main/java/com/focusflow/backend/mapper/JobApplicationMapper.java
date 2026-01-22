package com.focusflow.backend.mapper;

import com.focusflow.backend.dto.JobApplicationRequest;
import com.focusflow.backend.dto.JobApplicationResponse;
import com.focusflow.backend.dto.JobApplicationSyncRequest;
import com.focusflow.backend.entity.JobApplication;
import org.springframework.stereotype.Component;

/**
 * Responsibility: Maps JobApplication entities to API DTOs and back. Architecture: Mapper layer
 * responsible for translating persistence models. Why: Reduces repetitive mapping code and keeps
 * service logic focused.
 */
@Component
public class JobApplicationMapper {

  public JobApplicationResponse toResponse(JobApplication application) {
    return new JobApplicationResponse(
        application.getId(),
        application.getCompany(),
        application.getRole(),
        application.getLocation(),
        application.getSource(),
        application.getStatus(),
        application.getAppliedDate(),
        application.getNotes(),
        application.getUrl(),
        application.getClientUpdatedAt(),
        application.getServerUpdatedAt(),
        application.getCreatedAt(),
        application.getUpdatedAt(),
        application.getDeletedAt());
  }

  public void applyRequest(JobApplication application, JobApplicationRequest request) {
    application.setCompany(request.company());
    application.setRole(request.role());
    application.setLocation(request.location());
    application.setSource(request.source());
    application.setStatus(request.status());
    application.setAppliedDate(request.appliedDate());
    application.setNotes(request.notes());
    application.setUrl(request.url());
  }

  public void applySync(JobApplication application, JobApplicationSyncRequest request) {
    application.setCompany(request.company());
    application.setRole(request.role());
    application.setLocation(request.location());
    application.setSource(request.source());
    application.setStatus(request.status());
    application.setAppliedDate(request.appliedDate());
    application.setNotes(request.notes());
    application.setUrl(request.url());
  }
}
