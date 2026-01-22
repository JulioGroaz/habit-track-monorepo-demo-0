package com.focusflow.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Responsibility: Stores user goals and progress state for FocusFlow. Architecture: Domain entity
 * under the syncable, user-owned aggregate root. Why: Encapsulates goal metadata so services can
 * enforce ownership and lifecycle rules.
 */
@Entity
@Table(name = "goals")
public class Goal extends SyncableEntity {

  @Column(nullable = false, length = 120)
  private String title;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Column(name = "target_date")
  private LocalDate targetDate;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  private GoalStatus status;

  @Column(name = "completed_at")
  private Instant completedAt;

  public String getTitle() {
    return title;
  }

  public void setTitle(String title) {
    this.title = title;
  }

  public String getDescription() {
    return description;
  }

  public void setDescription(String description) {
    this.description = description;
  }

  public LocalDate getTargetDate() {
    return targetDate;
  }

  public void setTargetDate(LocalDate targetDate) {
    this.targetDate = targetDate;
  }

  public GoalStatus getStatus() {
    return status;
  }

  public void setStatus(GoalStatus status) {
    this.status = status;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public void setCompletedAt(Instant completedAt) {
    this.completedAt = completedAt;
  }
}
