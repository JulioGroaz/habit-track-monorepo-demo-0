package com.focusflow.backend.repository;

import com.focusflow.backend.entity.JobApplication;
import com.focusflow.backend.entity.JobApplicationSource;
import com.focusflow.backend.entity.JobApplicationStatus;
import com.focusflow.backend.entity.User;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Responsibility: Persistence operations for job applications. Architecture: Repository layer for
 * job application aggregates with ownership scoping. Why: Encapsulates filtering logic so services
 * can stay focused on business rules.
 */
public interface JobApplicationRepository extends JpaRepository<JobApplication, UUID> {
  Optional<JobApplication> findByIdAndOwner(UUID id, User owner);

  Optional<JobApplication> findByIdAndOwnerAndDeletedAtIsNull(UUID id, User owner);

  @Query(
      "select a from JobApplication a "
          + "where a.owner = :owner and a.deletedAt is null "
          + "and (:status is null or a.status = :status) "
          + "and (:source is null or a.source = :source)")
  Page<JobApplication> search(
      @Param("owner") User owner,
      @Param("status") JobApplicationStatus status,
      @Param("source") JobApplicationSource source,
      Pageable pageable);

  List<JobApplication> findByOwnerAndServerUpdatedAtGreaterThanEqual(User owner, Instant since);
}
