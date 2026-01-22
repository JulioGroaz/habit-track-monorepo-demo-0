package com.focusflow.backend.repository;

import com.focusflow.backend.entity.Routine;
import com.focusflow.backend.entity.User;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Responsibility: Persistence operations for routines. Architecture: Repository layer for routine
 * aggregates with ownership filtering. Why: Centralizes soft-delete and sync queries so services
 * stay focused on rules.
 */
public interface RoutineRepository extends JpaRepository<Routine, UUID> {
  Optional<Routine> findByIdAndOwner(UUID id, User owner);

  Optional<Routine> findByIdAndOwnerAndDeletedAtIsNull(UUID id, User owner);

  Page<Routine> findByOwnerAndDeletedAtIsNull(User owner, Pageable pageable);

  Page<Routine> findByOwnerAndActiveAndDeletedAtIsNull(
      User owner, boolean active, Pageable pageable);

  List<Routine> findByOwnerAndServerUpdatedAtGreaterThanEqual(User owner, Instant since);
}
