package com.focusflow.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.focusflow.backend.dto.GoalRequest;
import com.focusflow.backend.entity.Goal;
import com.focusflow.backend.entity.GoalStatus;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.GoalMapper;
import com.focusflow.backend.repository.GoalRepository;
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
 * Responsibility: Unit tests for goal service business rules. Architecture: Service-layer test
 * verifying timestamp and completion logic. Why: Ensures goal sync metadata is applied consistently
 * without hitting the database.
 */
@ExtendWith(MockitoExtension.class)
class GoalServiceTest {

  @Mock private GoalRepository goalRepository;

  private GoalService goalService;
  private Clock clock;

  @BeforeEach
  void setUp() {
    clock = Clock.fixed(Instant.parse("2024-01-01T00:00:00Z"), ZoneOffset.UTC);
    goalService = new GoalService(goalRepository, new GoalMapper(), clock);
    when(goalRepository.save(any(Goal.class))).thenAnswer(invocation -> invocation.getArgument(0));
  }

  @Test
  void createGoalSetsServerAndClientTimestamps() {
    User user = new User(UUID.randomUUID(), "user@example.com", "hash");
    GoalRequest request = new GoalRequest("Read", null, null, GoalStatus.COMPLETED, null, null);

    Goal goal = goalService.createGoal(user, request);

    assertThat(goal.getServerUpdatedAt()).isEqualTo(Instant.now(clock));
    assertThat(goal.getClientUpdatedAt()).isEqualTo(Instant.now(clock));
    assertThat(goal.getCompletedAt()).isEqualTo(Instant.now(clock));
    assertThat(goal.getOwner()).isEqualTo(user);
  }
}
