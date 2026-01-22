package com.focusflow.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Responsibility: Records a daily completion snapshot for a routine. Architecture: Domain entity
 * tied to routines and used in sync and analytics APIs. Why: Enforces uniqueness per routine/day to
 * keep check-ins idempotent for sync.
 */
@Entity
@Table(
    name = "check_ins",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "routine_id", "date"}))
public class CheckIn extends SyncableEntity {

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "routine_id", nullable = false)
  private Routine routine;

  @Column(name = "routine_id", nullable = false, insertable = false, updatable = false)
  private UUID routineId;

  @Column(name = "date", nullable = false)
  private LocalDate date;

  @Column(name = "completed", nullable = false)
  private boolean completed;

  @Column(name = "completed_at")
  private Instant completedAt;

  public Routine getRoutine() {
    return routine;
  }

  public UUID getRoutineId() {
    return routineId;
  }

  public void setRoutine(Routine routine) {
    this.routine = routine;
  }

  public LocalDate getDate() {
    return date;
  }

  public void setDate(LocalDate date) {
    this.date = date;
  }

  public boolean isCompleted() {
    return completed;
  }

  public void setCompleted(boolean completed) {
    this.completed = completed;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public void setCompletedAt(Instant completedAt) {
    this.completedAt = completedAt;
  }
}
