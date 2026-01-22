package com.focusflow.backend.mapper;

import com.focusflow.backend.dto.CheckInRequest;
import com.focusflow.backend.dto.CheckInResponse;
import com.focusflow.backend.dto.CheckInSyncRequest;
import com.focusflow.backend.entity.CheckIn;
import org.springframework.stereotype.Component;

/**
 * Responsibility: Maps CheckIn entities to DTOs and back. Architecture: Mapper layer isolating
 * transport models from persistence. Why: Keeps routine linkage and completion fields consistent
 * across endpoints.
 */
@Component
public class CheckInMapper {

  public CheckInResponse toResponse(CheckIn checkIn) {
    return new CheckInResponse(
        checkIn.getId(),
        checkIn.getRoutineId(),
        checkIn.getDate(),
        checkIn.isCompleted(),
        checkIn.getCompletedAt(),
        checkIn.getClientUpdatedAt(),
        checkIn.getServerUpdatedAt(),
        checkIn.getCreatedAt(),
        checkIn.getUpdatedAt(),
        checkIn.getDeletedAt());
  }

  public void applyRequest(CheckIn checkIn, CheckInRequest request) {
    checkIn.setDate(request.date());
    checkIn.setCompleted(Boolean.TRUE.equals(request.completed()));
    checkIn.setCompletedAt(request.completedAt());
  }

  public void applySync(CheckIn checkIn, CheckInSyncRequest request) {
    if (request.date() != null) {
      checkIn.setDate(request.date());
    }
    if (request.completed() != null) {
      checkIn.setCompleted(Boolean.TRUE.equals(request.completed()));
    }
    checkIn.setCompletedAt(request.completedAt());
  }
}
