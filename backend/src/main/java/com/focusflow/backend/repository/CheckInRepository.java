package com.focusflow.backend.repository;

import com.focusflow.backend.entity.CheckIn;
import com.focusflow.backend.entity.Routine;
import com.focusflow.backend.entity.User;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Responsibility: Persistence operations for check-ins. Architecture: Repository layer for check-in
 * aggregates with ownership filtering. Why: Provides optimized queries for date/routine filtering
 * and sync pulls.
 */
public interface CheckInRepository extends JpaRepository<CheckIn, UUID> {
  Optional<CheckIn> findByIdAndOwner(UUID id, User owner);

  Optional<CheckIn> findByIdAndOwnerAndDeletedAtIsNull(UUID id, User owner);

  boolean existsByOwnerAndRoutineAndDateAndDeletedAtIsNull(
      User owner, Routine routine, LocalDate date);

  Optional<CheckIn> findByOwnerAndRoutineAndDateAndDeletedAtIsNull(
      User owner, Routine routine, LocalDate date);

  @Query(
      "select c from CheckIn c "
          + "where c.owner = :owner and c.deletedAt is null "
          + "and (:routineId is null or c.routine.id = :routineId) "
          + "and (:startDate is null or c.date >= :startDate) "
          + "and (:endDate is null or c.date <= :endDate)")
  Page<CheckIn> search(
      @Param("owner") User owner,
      @Param("routineId") UUID routineId,
      @Param("startDate") LocalDate startDate,
      @Param("endDate") LocalDate endDate,
      Pageable pageable);

  List<CheckIn> findByOwnerAndServerUpdatedAtGreaterThanEqual(User owner, Instant since);
}
