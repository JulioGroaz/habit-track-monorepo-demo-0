package com.focusflow.backend.repository;

import com.focusflow.backend.entity.Goal;
import com.focusflow.backend.entity.GoalStatus;
import com.focusflow.backend.entity.User;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Responsibility: Persistence operations for goals. Architecture: Repository layer for goal
 * aggregates with user scoping. Why: Encapsulates query patterns for soft delete and sync-aware
 * reads.
 */
public interface GoalRepository extends JpaRepository<Goal, UUID> {
  Optional<Goal> findByIdAndOwner(UUID id, User owner);

  Optional<Goal> findByIdAndOwnerAndDeletedAtIsNull(UUID id, User owner);

  Page<Goal> findByOwnerAndDeletedAtIsNull(User owner, Pageable pageable);

  Page<Goal> findByOwnerAndStatusAndDeletedAtIsNull(
      User owner, GoalStatus status, Pageable pageable);

  List<Goal> findByOwnerAndServerUpdatedAtGreaterThanEqual(User owner, Instant since);
}
