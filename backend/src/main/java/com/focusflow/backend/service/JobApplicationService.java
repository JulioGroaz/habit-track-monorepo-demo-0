package com.focusflow.backend.service;

import com.focusflow.backend.dto.JobApplicationRequest;
import com.focusflow.backend.entity.JobApplication;
import com.focusflow.backend.entity.JobApplicationSource;
import com.focusflow.backend.entity.JobApplicationStatus;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.exception.ResourceNotFoundException;
import com.focusflow.backend.mapper.JobApplicationMapper;
import com.focusflow.backend.repository.JobApplicationRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

/**
 * Responsibility: Implements job application business rules and persistence orchestration.
 * Architecture: Service layer between controllers and repositories for job applications. Why:
 * Centralizes status management, soft deletes, and sync timestamp handling.
 */
@Service
public class JobApplicationService {

  private final JobApplicationRepository jobApplicationRepository;
  private final JobApplicationMapper jobApplicationMapper;
  private final Clock clock;

  public JobApplicationService(
      JobApplicationRepository jobApplicationRepository,
      JobApplicationMapper jobApplicationMapper,
      Clock clock) {
    this.jobApplicationRepository = jobApplicationRepository;
    this.jobApplicationMapper = jobApplicationMapper;
    this.clock = clock;
  }

  public Page<JobApplication> listApplications(
      User user, JobApplicationStatus status, JobApplicationSource source, Pageable pageable) {
    return jobApplicationRepository.search(user, status, source, pageable);
  }

  public JobApplication createApplication(User user, JobApplicationRequest request) {
    JobApplication application = new JobApplication();
    application.setId(UUID.randomUUID());
    application.setOwner(user);
    jobApplicationMapper.applyRequest(application, request);

    Instant now = Instant.now(clock);
    application.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    application.setServerUpdatedAt(now);

    return jobApplicationRepository.save(application);
  }

  public JobApplication updateApplication(User user, UUID id, JobApplicationRequest request) {
    JobApplication application =
        jobApplicationRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

    jobApplicationMapper.applyRequest(application, request);

    Instant now = Instant.now(clock);
    application.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    application.setServerUpdatedAt(now);

    return jobApplicationRepository.save(application);
  }

  public void deleteApplication(User user, UUID id) {
    JobApplication application =
        jobApplicationRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

    Instant now = Instant.now(clock);
    application.setDeletedAt(now);
    application.setClientUpdatedAt(now);
    application.setServerUpdatedAt(now);
    jobApplicationRepository.save(application);
  }

  private Instant defaultClientUpdatedAt(Instant clientUpdatedAt, Instant now) {
    return clientUpdatedAt != null ? clientUpdatedAt : now;
  }
}
