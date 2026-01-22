package com.focusflow.backend.entity;

/**
 * Responsibility: Enumerates the inbound channels for job applications. Architecture: Domain enum
 * reused in persistence and API layers. Why: Keeps source values consistent for analytics and
 * filtering.
 */
public enum JobApplicationSource {
  LINKEDIN,
  INDEED,
  WEBSITE,
  REFERRAL,
  OTHER
}
