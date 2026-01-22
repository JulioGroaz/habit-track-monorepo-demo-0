package com.focusflow.backend.mapper;

import com.focusflow.backend.dto.GoalRequest;
import com.focusflow.backend.dto.GoalResponse;
import com.focusflow.backend.dto.GoalSyncRequest;
import com.focusflow.backend.entity.Goal;
import org.springframework.stereotype.Component;

/**
 * Responsibility: Maps Goal entities to API DTOs and back. Architecture: Mapper layer separating
 * persistence models from transport models. Why: Keeps controllers/services focused on business
 * rules instead of boilerplate mapping.
 */
@Component
public class GoalMapper {

  public GoalResponse toResponse(Goal goal) {
    return new GoalResponse(
        goal.getId(),
        goal.getTitle(),
        goal.getDescription(),
        goal.getTargetDate(),
        goal.getStatus(),
        goal.getCompletedAt(),
        goal.getClientUpdatedAt(),
        goal.getServerUpdatedAt(),
        goal.getCreatedAt(),
        goal.getUpdatedAt(),
        goal.getDeletedAt());
  }

  public void applyRequest(Goal goal, GoalRequest request) {
    goal.setTitle(request.title());
    goal.setDescription(request.description());
    goal.setTargetDate(request.targetDate());
    goal.setStatus(request.status());
    goal.setCompletedAt(request.completedAt());
  }

  public void applySync(Goal goal, GoalSyncRequest request) {
    goal.setTitle(request.title());
    goal.setDescription(request.description());
    goal.setTargetDate(request.targetDate());
    goal.setStatus(request.status());
    goal.setCompletedAt(request.completedAt());
  }
}
