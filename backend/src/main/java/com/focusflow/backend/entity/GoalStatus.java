package com.focusflow.backend.entity;

/**
 * Responsibility: Enumerates lifecycle states for goals. Architecture: Domain enum referenced by
 * Goal entities and DTOs. Why: Prevents invalid statuses and aligns persistence with API contracts.
 */
public enum GoalStatus {
  ACTIVE,
  COMPLETED,
  ARCHIVED
}
