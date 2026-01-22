package com.focusflow.backend.service;

import com.focusflow.backend.dto.CheckInResponse;
import com.focusflow.backend.dto.CheckInSyncRequest;
import com.focusflow.backend.dto.GoalResponse;
import com.focusflow.backend.dto.GoalSyncRequest;
import com.focusflow.backend.dto.JobApplicationResponse;
import com.focusflow.backend.dto.JobApplicationSyncRequest;
import com.focusflow.backend.dto.RoutineResponse;
import com.focusflow.backend.dto.RoutineSyncRequest;
import com.focusflow.backend.dto.SyncConflict;
import com.focusflow.backend.dto.SyncPullResponse;
import com.focusflow.backend.dto.SyncPushRequest;
import com.focusflow.backend.dto.SyncPushResponse;
import com.focusflow.backend.entity.CheckIn;
import com.focusflow.backend.entity.Goal;
import com.focusflow.backend.entity.GoalStatus;
import com.focusflow.backend.entity.JobApplication;
import com.focusflow.backend.entity.Routine;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.CheckInMapper;
import com.focusflow.backend.mapper.GoalMapper;
import com.focusflow.backend.mapper.JobApplicationMapper;
import com.focusflow.backend.mapper.RoutineMapper;
import com.focusflow.backend.repository.CheckInRepository;
import com.focusflow.backend.repository.GoalRepository;
import com.focusflow.backend.repository.JobApplicationRepository;
import com.focusflow.backend.repository.RoutineRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Responsibility: Applies offline-first sync logic and conflict detection. Architecture: Service
 * layer coordinating repositories and mappers for sync workflows. Why: Centralizes conflict rules
 * so controllers remain thin and consistent across entities.
 */
@Service
public class SyncService {

  private static final String REASON_SERVER_NEWER = "SERVER_NEWER";
  private static final String REASON_MISSING_DEPENDENCY = "MISSING_DEPENDENCY";
  private static final String REASON_DUPLICATE = "DUPLICATE";

  private final GoalRepository goalRepository;
  private final RoutineRepository routineRepository;
  private final CheckInRepository checkInRepository;
  private final JobApplicationRepository jobApplicationRepository;
  private final GoalMapper goalMapper;
  private final RoutineMapper routineMapper;
  private final CheckInMapper checkInMapper;
  private final JobApplicationMapper jobApplicationMapper;
  private final Clock clock;

  public SyncService(
      GoalRepository goalRepository,
      RoutineRepository routineRepository,
      CheckInRepository checkInRepository,
      JobApplicationRepository jobApplicationRepository,
      GoalMapper goalMapper,
      RoutineMapper routineMapper,
      CheckInMapper checkInMapper,
      JobApplicationMapper jobApplicationMapper,
      Clock clock) {
    this.goalRepository = goalRepository;
    this.routineRepository = routineRepository;
    this.checkInRepository = checkInRepository;
    this.jobApplicationRepository = jobApplicationRepository;
    this.goalMapper = goalMapper;
    this.routineMapper = routineMapper;
    this.checkInMapper = checkInMapper;
    this.jobApplicationMapper = jobApplicationMapper;
    this.clock = clock;
  }

  @Transactional
  public SyncPushResponse push(User user, SyncPushRequest request) {
    Instant now = Instant.now(clock);
    List<GoalResponse> goals = new ArrayList<>();
    List<RoutineResponse> routines = new ArrayList<>();
    List<CheckInResponse> checkIns = new ArrayList<>();
    List<JobApplicationResponse> applications = new ArrayList<>();
    List<SyncConflict> conflicts = new ArrayList<>();

    // The sync algorithm is intentionally consistent across entities:
    // 1) Load the server version (including soft-deleted records).
    // 2) Compare client_updated_at with server_updated_at.
    // 3) Apply if the client is newer or equal; otherwise return a conflict payload.
    processGoals(user, safeList(request.goals()), now, goals, conflicts);
    processRoutines(user, safeList(request.routines()), now, routines, conflicts);
    processCheckIns(user, safeList(request.checkIns()), now, checkIns, conflicts);
    processApplications(user, safeList(request.applications()), now, applications, conflicts);

    return new SyncPushResponse(goals, routines, checkIns, applications, conflicts, now);
  }

  public SyncPullResponse pull(User user, Instant since) {
    Instant effectiveSince = since != null ? since : Instant.EPOCH;

    List<GoalResponse> goals =
        goalRepository.findByOwnerAndServerUpdatedAtGreaterThanEqual(user, effectiveSince).stream()
            .map(goalMapper::toResponse)
            .toList();
    List<RoutineResponse> routines =
        routineRepository
            .findByOwnerAndServerUpdatedAtGreaterThanEqual(user, effectiveSince)
            .stream()
            .map(routineMapper::toResponse)
            .toList();
    List<CheckInResponse> checkIns =
        checkInRepository
            .findByOwnerAndServerUpdatedAtGreaterThanEqual(user, effectiveSince)
            .stream()
            .map(checkInMapper::toResponse)
            .toList();
    List<JobApplicationResponse> applications =
        jobApplicationRepository
            .findByOwnerAndServerUpdatedAtGreaterThanEqual(user, effectiveSince)
            .stream()
            .map(jobApplicationMapper::toResponse)
            .toList();

    return new SyncPullResponse(goals, routines, checkIns, applications, Instant.now(clock));
  }

  private void processGoals(
      User user,
      List<GoalSyncRequest> payloads,
      Instant now,
      List<GoalResponse> accepted,
      List<SyncConflict> conflicts) {
    for (GoalSyncRequest payload : payloads) {
      Goal existing = goalRepository.findByIdAndOwner(payload.id(), user).orElse(null);

      if (payload.deletedAt() != null) {
        if (existing == null) {
          continue;
        }
        if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
          conflicts.add(
              new SyncConflict(
                  "GOAL",
                  payload.id(),
                  REASON_SERVER_NEWER,
                  goalMapper.toResponse(existing),
                  payload));
          continue;
        }
        existing.setDeletedAt(payload.deletedAt());
        existing.setClientUpdatedAt(payload.clientUpdatedAt());
        existing.setServerUpdatedAt(now);
        accepted.add(goalMapper.toResponse(goalRepository.save(existing)));
        continue;
      }

      validateGoalPayload(payload);

      if (existing == null) {
        Goal created = new Goal();
        created.setId(payload.id());
        created.setOwner(user);
        goalMapper.applySync(created, payload);
        created.setClientUpdatedAt(payload.clientUpdatedAt());
        created.setServerUpdatedAt(now);
        applyGoalCompletion(created, payload, now);
        accepted.add(goalMapper.toResponse(goalRepository.save(created)));
        continue;
      }

      // server_updated_at is the authoritative write clock; reject older client updates to avoid
      // data loss.
      if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
        conflicts.add(
            new SyncConflict(
                "GOAL",
                payload.id(),
                REASON_SERVER_NEWER,
                goalMapper.toResponse(existing),
                payload));
        continue;
      }

      goalMapper.applySync(existing, payload);
      existing.setDeletedAt(null);
      existing.setClientUpdatedAt(payload.clientUpdatedAt());
      existing.setServerUpdatedAt(now);
      applyGoalCompletion(existing, payload, now);
      accepted.add(goalMapper.toResponse(goalRepository.save(existing)));
    }
  }

  private void processRoutines(
      User user,
      List<RoutineSyncRequest> payloads,
      Instant now,
      List<RoutineResponse> accepted,
      List<SyncConflict> conflicts) {
    for (RoutineSyncRequest payload : payloads) {
      Routine existing = routineRepository.findByIdAndOwner(payload.id(), user).orElse(null);

      if (payload.deletedAt() != null) {
        if (existing == null) {
          continue;
        }
        if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
          conflicts.add(
              new SyncConflict(
                  "ROUTINE",
                  payload.id(),
                  REASON_SERVER_NEWER,
                  routineMapper.toResponse(existing),
                  payload));
          continue;
        }
        existing.setDeletedAt(payload.deletedAt());
        existing.setClientUpdatedAt(payload.clientUpdatedAt());
        existing.setServerUpdatedAt(now);
        accepted.add(routineMapper.toResponse(routineRepository.save(existing)));
        continue;
      }

      validateRoutinePayload(payload);

      if (existing == null) {
        Routine created = new Routine();
        created.setId(payload.id());
        created.setOwner(user);
        routineMapper.applySync(created, payload);
        created.setClientUpdatedAt(payload.clientUpdatedAt());
        created.setServerUpdatedAt(now);
        accepted.add(routineMapper.toResponse(routineRepository.save(created)));
        continue;
      }

      // server_updated_at is the authoritative write clock; reject older client updates to avoid
      // data loss.
      if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
        conflicts.add(
            new SyncConflict(
                "ROUTINE",
                payload.id(),
                REASON_SERVER_NEWER,
                routineMapper.toResponse(existing),
                payload));
        continue;
      }

      routineMapper.applySync(existing, payload);
      existing.setDeletedAt(null);
      existing.setClientUpdatedAt(payload.clientUpdatedAt());
      existing.setServerUpdatedAt(now);
      accepted.add(routineMapper.toResponse(routineRepository.save(existing)));
    }
  }

  private void processCheckIns(
      User user,
      List<CheckInSyncRequest> payloads,
      Instant now,
      List<CheckInResponse> accepted,
      List<SyncConflict> conflicts) {
    for (CheckInSyncRequest payload : payloads) {
      CheckIn existing = checkInRepository.findByIdAndOwner(payload.id(), user).orElse(null);

      if (payload.deletedAt() != null) {
        if (existing == null) {
          continue;
        }
        if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
          conflicts.add(
              new SyncConflict(
                  "CHECK_IN",
                  payload.id(),
                  REASON_SERVER_NEWER,
                  checkInMapper.toResponse(existing),
                  payload));
          continue;
        }
        existing.setDeletedAt(payload.deletedAt());
        existing.setClientUpdatedAt(payload.clientUpdatedAt());
        existing.setServerUpdatedAt(now);
        accepted.add(checkInMapper.toResponse(checkInRepository.save(existing)));
        continue;
      }

      validateCheckInPayload(payload);

      // Check-ins must reference an existing routine; otherwise we'd create a dangling foreign key.
      Routine routine =
          routineRepository
              .findByIdAndOwnerAndDeletedAtIsNull(payload.routineId(), user)
              .orElse(null);
      if (routine == null) {
        conflicts.add(
            new SyncConflict("CHECK_IN", payload.id(), REASON_MISSING_DEPENDENCY, null, payload));
        continue;
      }

      if (existing == null) {
        // Enforce uniqueness (user_id, routine_id, date) to keep sync idempotent.
        Optional<CheckIn> duplicate =
            checkInRepository.findByOwnerAndRoutineAndDateAndDeletedAtIsNull(
                user, routine, payload.date());
        if (duplicate.isPresent()) {
          conflicts.add(
              new SyncConflict(
                  "CHECK_IN",
                  payload.id(),
                  REASON_DUPLICATE,
                  checkInMapper.toResponse(duplicate.get()),
                  payload));
          continue;
        }
        CheckIn created = new CheckIn();
        created.setId(payload.id());
        created.setOwner(user);
        created.setRoutine(routine);
        checkInMapper.applySync(created, payload);
        created.setClientUpdatedAt(payload.clientUpdatedAt());
        created.setServerUpdatedAt(now);
        applyCheckInCompletion(created, payload, now);
        accepted.add(checkInMapper.toResponse(checkInRepository.save(created)));
        continue;
      }

      // server_updated_at is the authoritative write clock; reject older client updates to avoid
      // data loss.
      if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
        conflicts.add(
            new SyncConflict(
                "CHECK_IN",
                payload.id(),
                REASON_SERVER_NEWER,
                checkInMapper.toResponse(existing),
                payload));
        continue;
      }

      boolean routineChanged = !Objects.equals(existing.getRoutine().getId(), routine.getId());
      boolean dateChanged = !Objects.equals(existing.getDate(), payload.date());
      // Re-validate uniqueness if the routine or date changes to avoid violating constraints.
      if (routineChanged || dateChanged) {
        Optional<CheckIn> duplicate =
            checkInRepository.findByOwnerAndRoutineAndDateAndDeletedAtIsNull(
                user, routine, payload.date());
        if (duplicate.isPresent()) {
          conflicts.add(
              new SyncConflict(
                  "CHECK_IN",
                  payload.id(),
                  REASON_DUPLICATE,
                  checkInMapper.toResponse(duplicate.get()),
                  payload));
          continue;
        }
      }

      existing.setRoutine(routine);
      checkInMapper.applySync(existing, payload);
      existing.setDeletedAt(null);
      existing.setClientUpdatedAt(payload.clientUpdatedAt());
      existing.setServerUpdatedAt(now);
      applyCheckInCompletion(existing, payload, now);
      accepted.add(checkInMapper.toResponse(checkInRepository.save(existing)));
    }
  }

  private void processApplications(
      User user,
      List<JobApplicationSyncRequest> payloads,
      Instant now,
      List<JobApplicationResponse> accepted,
      List<SyncConflict> conflicts) {
    for (JobApplicationSyncRequest payload : payloads) {
      JobApplication existing =
          jobApplicationRepository.findByIdAndOwner(payload.id(), user).orElse(null);

      if (payload.deletedAt() != null) {
        if (existing == null) {
          continue;
        }
        if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
          conflicts.add(
              new SyncConflict(
                  "JOB_APPLICATION",
                  payload.id(),
                  REASON_SERVER_NEWER,
                  jobApplicationMapper.toResponse(existing),
                  payload));
          continue;
        }
        existing.setDeletedAt(payload.deletedAt());
        existing.setClientUpdatedAt(payload.clientUpdatedAt());
        existing.setServerUpdatedAt(now);
        accepted.add(jobApplicationMapper.toResponse(jobApplicationRepository.save(existing)));
        continue;
      }

      validateJobApplicationPayload(payload);

      if (existing == null) {
        JobApplication created = new JobApplication();
        created.setId(payload.id());
        created.setOwner(user);
        jobApplicationMapper.applySync(created, payload);
        created.setClientUpdatedAt(payload.clientUpdatedAt());
        created.setServerUpdatedAt(now);
        accepted.add(jobApplicationMapper.toResponse(jobApplicationRepository.save(created)));
        continue;
      }

      // server_updated_at is the authoritative write clock; reject older client updates to avoid
      // data loss.
      if (isServerNewer(existing.getServerUpdatedAt(), payload.clientUpdatedAt())) {
        conflicts.add(
            new SyncConflict(
                "JOB_APPLICATION",
                payload.id(),
                REASON_SERVER_NEWER,
                jobApplicationMapper.toResponse(existing),
                payload));
        continue;
      }

      jobApplicationMapper.applySync(existing, payload);
      existing.setDeletedAt(null);
      existing.setClientUpdatedAt(payload.clientUpdatedAt());
      existing.setServerUpdatedAt(now);
      accepted.add(jobApplicationMapper.toResponse(jobApplicationRepository.save(existing)));
    }
  }

  private void applyGoalCompletion(Goal goal, GoalSyncRequest payload, Instant now) {
    if (goal.getStatus() == GoalStatus.COMPLETED) {
      Instant completedAt =
          payload.completedAt() != null ? payload.completedAt() : payload.clientUpdatedAt();
      goal.setCompletedAt(completedAt != null ? completedAt : now);
      return;
    }
    if (goal.getStatus() == GoalStatus.ARCHIVED) {
      if (payload.completedAt() != null) {
        goal.setCompletedAt(payload.completedAt());
      }
      return;
    }
    goal.setCompletedAt(null);
  }

  private void applyCheckInCompletion(CheckIn checkIn, CheckInSyncRequest payload, Instant now) {
    if (Boolean.TRUE.equals(payload.completed())) {
      Instant completedAt =
          payload.completedAt() != null ? payload.completedAt() : payload.clientUpdatedAt();
      checkIn.setCompletedAt(completedAt != null ? completedAt : now);
      checkIn.setCompleted(true);
      return;
    }
    checkIn.setCompleted(false);
    checkIn.setCompletedAt(null);
  }

  private boolean isServerNewer(Instant serverUpdatedAt, Instant clientUpdatedAt) {
    if (serverUpdatedAt == null || clientUpdatedAt == null) {
      return false;
    }
    return serverUpdatedAt.isAfter(clientUpdatedAt);
  }

  private <T> List<T> safeList(List<T> payloads) {
    return payloads != null ? payloads : Collections.emptyList();
  }

  private void validateGoalPayload(GoalSyncRequest payload) {
    if (payload.title() == null || payload.title().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Goal title is required");
    }
    if (payload.status() == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Goal status is required");
    }
  }

  private void validateRoutinePayload(RoutineSyncRequest payload) {
    if (payload.title() == null || payload.title().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Routine title is required");
    }
    if (payload.scheduleDays() == null || payload.scheduleDays().isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Routine scheduleDays is required");
    }
    if (payload.active() == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Routine active flag is required");
    }
  }

  private void validateCheckInPayload(CheckInSyncRequest payload) {
    if (payload.routineId() == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Check-in routineId is required");
    }
    if (payload.date() == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Check-in date is required");
    }
    if (payload.completed() == null) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST, "Check-in completed flag is required");
    }
  }

  private void validateJobApplicationPayload(JobApplicationSyncRequest payload) {
    if (payload.company() == null || payload.company().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Application company is required");
    }
    if (payload.role() == null || payload.role().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Application role is required");
    }
    if (payload.source() == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Application source is required");
    }
    if (payload.status() == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Application status is required");
    }
  }
}
