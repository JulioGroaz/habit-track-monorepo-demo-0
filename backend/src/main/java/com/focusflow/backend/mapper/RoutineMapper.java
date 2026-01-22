package com.focusflow.backend.mapper;

import com.focusflow.backend.dto.RoutineRequest;
import com.focusflow.backend.dto.RoutineResponse;
import com.focusflow.backend.dto.RoutineSyncRequest;
import com.focusflow.backend.entity.Routine;
import org.springframework.stereotype.Component;

/**
 * Responsibility: Maps Routine entities to DTOs and back. Architecture: Mapper layer for
 * translating API schedules to DB bitmasks. Why: Keeps schedule conversion logic centralized and
 * reusable.
 */
@Component
public class RoutineMapper {

  public RoutineResponse toResponse(Routine routine) {
    return new RoutineResponse(
        routine.getId(),
        routine.getTitle(),
        routine.getColorTag(),
        ScheduleDaysMapper.fromMask(routine.getScheduleDays()),
        routine.isActive(),
        routine.getClientUpdatedAt(),
        routine.getServerUpdatedAt(),
        routine.getCreatedAt(),
        routine.getUpdatedAt(),
        routine.getDeletedAt());
  }

  public void applyRequest(Routine routine, RoutineRequest request) {
    routine.setTitle(request.title());
    routine.setColorTag(request.colorTag());
    routine.setScheduleDays(ScheduleDaysMapper.toMask(request.scheduleDays()));
    routine.setActive(Boolean.TRUE.equals(request.active()));
  }

  public void applySync(Routine routine, RoutineSyncRequest request) {
    routine.setTitle(request.title());
    routine.setColorTag(request.colorTag());
    if (request.scheduleDays() != null) {
      routine.setScheduleDays(ScheduleDaysMapper.toMask(request.scheduleDays()));
    }
    if (request.active() != null) {
      routine.setActive(Boolean.TRUE.equals(request.active()));
    }
  }
}
