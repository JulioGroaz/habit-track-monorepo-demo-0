package com.focusflow.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.focusflow.backend.dto.RoutineRequest;
import com.focusflow.backend.entity.Routine;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.RoutineMapper;
import com.focusflow.backend.mapper.ScheduleDaysMapper;
import com.focusflow.backend.repository.RoutineRepository;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Responsibility: Unit tests for routine service business rules. Architecture: Service-layer test
 * verifying schedule bitmask mapping. Why: Ensures API schedule arrays map deterministically to
 * database storage.
 */
@ExtendWith(MockitoExtension.class)
class RoutineServiceTest {

  @Mock private RoutineRepository routineRepository;

  private RoutineService routineService;
  private Clock clock;

  @BeforeEach
  void setUp() {
    clock = Clock.fixed(Instant.parse("2024-01-01T00:00:00Z"), ZoneOffset.UTC);
    routineService = new RoutineService(routineRepository, new RoutineMapper(), clock);
    when(routineRepository.save(any(Routine.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));
  }

  @Test
  void createRoutineMapsScheduleDaysToMask() {
    User user = new User(UUID.randomUUID(), "user@example.com", "hash");
    List<DayOfWeek> schedule = List.of(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY);
    RoutineRequest request = new RoutineRequest("Gym", "#FFAA00", schedule, true, null);

    Routine routine = routineService.createRoutine(user, request);

    assertThat(routine.getScheduleDays()).isEqualTo(ScheduleDaysMapper.toMask(schedule));
    assertThat(routine.getServerUpdatedAt()).isEqualTo(Instant.now(clock));
  }
}
