package com.focusflow.backend.service;

import com.focusflow.backend.dto.GoalRequest;
import com.focusflow.backend.entity.Goal;
import com.focusflow.backend.entity.GoalStatus;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.exception.ResourceNotFoundException;
import com.focusflow.backend.mapper.GoalMapper;
import com.focusflow.backend.repository.GoalRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

/**
 * Responsibility: Implements goal-related business rules and persistence orchestration.
 * Architecture: Service layer between controllers and repositories for goal aggregates. Why: Keeps
 * controllers thin while enforcing ownership, soft delete, and sync timestamps.
 */
@Service
public class GoalService {

  private final GoalRepository goalRepository;
  private final GoalMapper goalMapper;
  private final Clock clock;

  public GoalService(GoalRepository goalRepository, GoalMapper goalMapper, Clock clock) {
    this.goalRepository = goalRepository;
    this.goalMapper = goalMapper;
    this.clock = clock;
  }

  public Page<Goal> listGoals(User user, GoalStatus status, Pageable pageable) {
    if (status == null) {
      return goalRepository.findByOwnerAndDeletedAtIsNull(user, pageable);
    }
    return goalRepository.findByOwnerAndStatusAndDeletedAtIsNull(user, status, pageable);
  }

  public Goal createGoal(User user, GoalRequest request) {
    Goal goal = new Goal();
    goal.setId(UUID.randomUUID());
    goal.setOwner(user);
    goalMapper.applyRequest(goal, request);

    Instant now = Instant.now(clock);
    goal.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    goal.setServerUpdatedAt(now);
    applyCompletionRules(goal, request.completedAt(), now);

    return goalRepository.save(goal);
  }

  public Goal updateGoal(User user, UUID id, GoalRequest request) {
    Goal goal =
        goalRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Goal not found"));

    goalMapper.applyRequest(goal, request);

    Instant now = Instant.now(clock);
    goal.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    goal.setServerUpdatedAt(now);
    applyCompletionRules(goal, request.completedAt(), now);

    return goalRepository.save(goal);
  }

  public void deleteGoal(User user, UUID id) {
    Goal goal =
        goalRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Goal not found"));

    Instant now = Instant.now(clock);
    goal.setDeletedAt(now);
    goal.setClientUpdatedAt(now);
    goal.setServerUpdatedAt(now);
    goalRepository.save(goal);
  }

  private Instant defaultClientUpdatedAt(Instant clientUpdatedAt, Instant now) {
    return clientUpdatedAt != null ? clientUpdatedAt : now;
  }

  private void applyCompletionRules(Goal goal, Instant requestedCompletedAt, Instant now) {
    if (goal.getStatus() == GoalStatus.COMPLETED) {
      goal.setCompletedAt(requestedCompletedAt != null ? requestedCompletedAt : now);
      return;
    }
    if (goal.getStatus() == GoalStatus.ARCHIVED) {
      if (requestedCompletedAt != null) {
        goal.setCompletedAt(requestedCompletedAt);
      }
      return;
    }
    goal.setCompletedAt(null);
  }
}
