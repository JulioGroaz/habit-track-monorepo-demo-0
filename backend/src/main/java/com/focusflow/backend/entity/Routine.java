package com.focusflow.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * Responsibility: Stores recurring routines and scheduling metadata for a user. Architecture:
 * Domain entity participating in sync and exposed through routine APIs. Why: Captures routine
 * cadence in a compact form (bitmask) for fast sync and filtering.
 */
@Entity
@Table(name = "routines")
public class Routine extends SyncableEntity {

  @Column(nullable = false, length = 120)
  private String title;

  @Column(name = "color_tag", length = 30)
  private String colorTag;

  @Column(name = "schedule_days", nullable = false)
  private int scheduleDays;

  @Column(name = "is_active", nullable = false)
  private boolean active;

  public String getTitle() {
    return title;
  }

  public void setTitle(String title) {
    this.title = title;
  }

  public String getColorTag() {
    return colorTag;
  }

  public void setColorTag(String colorTag) {
    this.colorTag = colorTag;
  }

  public int getScheduleDays() {
    return scheduleDays;
  }

  public void setScheduleDays(int scheduleDays) {
    this.scheduleDays = scheduleDays;
  }

  public boolean isActive() {
    return active;
  }

  public void setActive(boolean active) {
    this.active = active;
  }
}
