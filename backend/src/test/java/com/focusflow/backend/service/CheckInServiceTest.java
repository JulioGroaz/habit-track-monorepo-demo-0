package com.focusflow.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.focusflow.backend.dto.CheckInRequest;
import com.focusflow.backend.entity.CheckIn;
import com.focusflow.backend.entity.Routine;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.CheckInMapper;
import com.focusflow.backend.repository.CheckInRepository;
import com.focusflow.backend.repository.RoutineRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Responsibility: Unit tests for check-in service business rules. Architecture: Service-layer test
 * verifying completion timestamp logic. Why: Ensures check-ins record completion times consistently
 * for sync.
 */
@ExtendWith(MockitoExtension.class)
class CheckInServiceTest {

  @Mock private CheckInRepository checkInRepository;
  @Mock private RoutineRepository routineRepository;

  private CheckInService checkInService;
  private Clock clock;

  @BeforeEach
  void setUp() {
    clock = Clock.fixed(Instant.parse("2024-01-01T00:00:00Z"), ZoneOffset.UTC);
    checkInService =
        new CheckInService(checkInRepository, routineRepository, new CheckInMapper(), clock);
    when(checkInRepository.save(any(CheckIn.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));
  }

  @Test
  void createCheckInSetsCompletionTimestamp() {
    User user = new User(UUID.randomUUID(), "user@example.com", "hash");
    Routine routine = new Routine();
    routine.setId(UUID.randomUUID());
    routine.setOwner(user);

    when(routineRepository.findByIdAndOwnerAndDeletedAtIsNull(routine.getId(), user))
        .thenReturn(Optional.of(routine));
    when(checkInRepository.existsByOwnerAndRoutineAndDateAndDeletedAtIsNull(
            user, routine, LocalDate.of(2024, 1, 1)))
        .thenReturn(false);

    CheckInRequest request =
        new CheckInRequest(routine.getId(), LocalDate.of(2024, 1, 1), true, null, null);

    CheckIn checkIn = checkInService.createCheckIn(user, request);

    assertThat(checkIn.isCompleted()).isTrue();
    assertThat(checkIn.getCompletedAt()).isEqualTo(Instant.now(clock));
    assertThat(checkIn.getServerUpdatedAt()).isEqualTo(Instant.now(clock));
  }
}
