package com.focusflow.backend.service;

import com.focusflow.backend.dto.RoutineRequest;
import com.focusflow.backend.entity.Routine;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.exception.ResourceNotFoundException;
import com.focusflow.backend.mapper.RoutineMapper;
import com.focusflow.backend.repository.RoutineRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

/**
 * Responsibility: Implements routine-related business rules and persistence orchestration.
 * Architecture: Service layer between controllers and repositories for routines. Why: Centralizes
 * schedule handling, soft deletes, and sync timestamp updates.
 */
@Service
public class RoutineService {

  private final RoutineRepository routineRepository;
  private final RoutineMapper routineMapper;
  private final Clock clock;

  public RoutineService(
      RoutineRepository routineRepository, RoutineMapper routineMapper, Clock clock) {
    this.routineRepository = routineRepository;
    this.routineMapper = routineMapper;
    this.clock = clock;
  }

  public Page<Routine> listRoutines(User user, Boolean active, Pageable pageable) {
    if (active == null) {
      return routineRepository.findByOwnerAndDeletedAtIsNull(user, pageable);
    }
    return routineRepository.findByOwnerAndActiveAndDeletedAtIsNull(user, active, pageable);
  }

  public Routine createRoutine(User user, RoutineRequest request) {
    Routine routine = new Routine();
    routine.setId(UUID.randomUUID());
    routine.setOwner(user);
    routineMapper.applyRequest(routine, request);

    Instant now = Instant.now(clock);
    routine.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    routine.setServerUpdatedAt(now);

    return routineRepository.save(routine);
  }

  public Routine updateRoutine(User user, UUID id, RoutineRequest request) {
    Routine routine =
        routineRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Routine not found"));

    routineMapper.applyRequest(routine, request);

    Instant now = Instant.now(clock);
    routine.setClientUpdatedAt(defaultClientUpdatedAt(request.clientUpdatedAt(), now));
    routine.setServerUpdatedAt(now);

    return routineRepository.save(routine);
  }

  public void deleteRoutine(User user, UUID id) {
    Routine routine =
        routineRepository
            .findByIdAndOwnerAndDeletedAtIsNull(id, user)
            .orElseThrow(() -> new ResourceNotFoundException("Routine not found"));

    Instant now = Instant.now(clock);
    routine.setDeletedAt(now);
    routine.setClientUpdatedAt(now);
    routine.setServerUpdatedAt(now);
    routineRepository.save(routine);
  }

  public Routine getRoutineForUser(User user, UUID id) {
    return routineRepository
        .findByIdAndOwnerAndDeletedAtIsNull(id, user)
        .orElseThrow(() -> new ResourceNotFoundException("Routine not found"));
  }

  private Instant defaultClientUpdatedAt(Instant clientUpdatedAt, Instant now) {
    return clientUpdatedAt != null ? clientUpdatedAt : now;
  }
}
