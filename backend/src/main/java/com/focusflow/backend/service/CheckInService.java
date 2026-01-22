package com.focusflow.backend.service;

import com.focusflow.backend.dto.CheckInRequest;
import com.focusflow.backend.entity.CheckIn;
import com.focusflow.backend.entity.Routine;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.exception.ConflictException;
import com.focusflow.backend.exception.ResourceNotFoundException;
import com.focusflow.backend.mapper.CheckInMapper;
import com.focusflow.backend.repository.CheckInRepository;
import com.focusflow.backend.repository.RoutineRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

/**
 * Responsibility: Implements check-in business rules and persistence orchestration. Architecture:
 * Service layer between controllers and repositories for check-ins. Why: Ensures routine ownership,
 * uniqueness, and sync timestamps are enforced consistently.
 */
@Service
public class CheckInService {

  private final CheckInRepository checkInRepository;
  private final RoutineRepository routineRepository;
  private final CheckInMapper checkInMapper;
  private final Clock clock;

  public CheckInService(
      CheckInRepository checkInRepository,
      RoutineRepository routineRepository,
      CheckInMapper checkInMapper,
      Clock clock) {
    this.checkInRepository = checkInRepository;
    this.routineRepository = routineRepository;
    this.checkInMapper = checkInMapper;
    this.clock = clock;
  }

  public Page<CheckIn> listCheckIns(
      User user, UUID routineId, LocalDate startDate, LocalDate endDate, Pageable pageable) {
    return checkInRepository.search(user, routineId, startDate, endDate, pageable);
  }

  public CheckIn createCheckIn(User user, CheckInRequest request) {
    Routine routine = getRoutineForUser(user, request.routineId());
    if (checkInRepository.existsByOwnerAndRoutineAndDateAndDeletedAtIsNull(
        user, routine, request.date())) {
      throw new ConflictException("Check-in already exists for that date");
    }

    CheckIn checkIn = new CheckIn();
    checkIn.setId(UUID.randomUUID());
    checkIn.setOwner(user);
    checkIn.setRoutine(routine);
    checkInMapper.applyRequest(checkIn, request);

    Instant now = Instant.now(clock);
    checkIn.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    checkIn.setServerUpdatedAt(now);
    applyCompletionRules(checkIn, request.completedAt(), now);

    return checkInRepository.save(checkIn);
  }

  public CheckIn updateCheckIn(User user, UUID id, CheckInRequest request) {
    CheckIn checkIn =
        checkInRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Check-in not found"));

    Routine routine = getRoutineForUser(user, request.routineId());
    if (!routine.getId().equals(checkIn.getRoutine().getId())
        || !request.date().equals(checkIn.getDate())) {
      if (checkInRepository.existsByOwnerAndRoutineAndDateAndDeletedAtIsNull(
          user, routine, request.date())) {
        throw new ConflictException("Check-in already exists for that date");
      }
    }

    checkIn.setRoutine(routine);
    checkInMapper.applyRequest(checkIn, request);

    Instant now = Instant.now(clock);
    checkIn.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    checkIn.setServerUpdatedAt(now);
    applyCompletionRules(checkIn, request.completedAt(), now);

    return checkInRepository.save(checkIn);
  }

  public void deleteCheckIn(User user, UUID id) {
    CheckIn checkIn =
        checkInRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Check-in not found"));

    Instant now = Instant.now(clock);
    checkIn.setDeletedAt(now);
    checkIn.setClientUpdatedAt(now);
    checkIn.setServerUpdatedAt(now);
    checkInRepository.save(checkIn);
  }

  private Routine getRoutineForUser(User user, UUID routineId) {
    return routineRepository
        .findByIdAndOwnerAndDeletedAtIsNull(routineId, user)
        .orElseThrow(() -> new ResourceNotFoundException("Routine not found"));
  }

  private Instant defaultClientUpdatedAt(Instant clientUpdatedAt, Instant now) {
    return clientUpdatedAt != null ? clientUpdatedAt : now;
  }

  private void applyCompletionRules(CheckIn checkIn, Instant requestedCompletedAt, Instant now) {
    if (checkIn.isCompleted()) {
      checkIn.setCompletedAt(requestedCompletedAt != null ? requestedCompletedAt : now);
      return;
    }
    checkIn.setCompletedAt(null);
  }
}
