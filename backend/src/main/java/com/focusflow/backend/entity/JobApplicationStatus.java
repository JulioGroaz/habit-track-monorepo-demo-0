package com.focusflow.backend.entity;

/**
 * Responsibility: Enumerates the lifecycle stages of a job application. Architecture: Domain enum
 * used by job application entities and DTOs. Why: Encodes finite status values so state transitions
 * stay explicit and validated.
 */
public enum JobApplicationStatus {
  DRAFT,
  APPLIED,
  INTERVIEW,
  OFFER,
  REJECTED,
  ARCHIVED
}
