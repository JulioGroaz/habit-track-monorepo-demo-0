package com.focusflow.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.focusflow.backend.dto.JobApplicationRequest;
import com.focusflow.backend.entity.JobApplication;
import com.focusflow.backend.entity.JobApplicationSource;
import com.focusflow.backend.entity.JobApplicationStatus;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.JobApplicationMapper;
import com.focusflow.backend.repository.JobApplicationRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Responsibility: Unit tests for job application service business rules. Architecture:
 * Service-layer test verifying sync timestamp updates. Why: Ensures application records carry
 * consistent server timestamps.
 */
@ExtendWith(MockitoExtension.class)
class JobApplicationServiceTest {

  @Mock private JobApplicationRepository jobApplicationRepository;

  private JobApplicationService jobApplicationService;
  private Clock clock;

  @BeforeEach
  void setUp() {
    clock = Clock.fixed(Instant.parse("2024-01-01T00:00:00Z"), ZoneOffset.UTC);
    jobApplicationService =
        new JobApplicationService(jobApplicationRepository, new JobApplicationMapper(), clock);
    when(jobApplicationRepository.save(any(JobApplication.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));
  }

  @Test
  void createApplicationSetsServerTimestamp() {
    User user = new User(UUID.randomUUID(), "user@example.com", "hash");
    JobApplicationRequest request =
        new JobApplicationRequest(
            "Acme",
            "Engineer",
            "Remote",
            JobApplicationSource.LINKEDIN,
            JobApplicationStatus.APPLIED,
            null,
            null,
            null,
            null);

    JobApplication application = jobApplicationService.createApplication(user, request);

    assertThat(application.getServerUpdatedAt()).isEqualTo(Instant.now(clock));
    assertThat(application.getOwner()).isEqualTo(user);
  }
}
