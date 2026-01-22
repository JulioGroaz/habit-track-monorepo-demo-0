package com.focusflow.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.time.LocalDate;

/**
 * Responsibility: Tracks job application progress for a user. Architecture: Domain entity
 * synchronized across devices and exposed via APIs. Why: Centralizes application metadata to
 * support workflows and status analytics.
 */
@Entity
@Table(name = "job_applications")
public class JobApplication extends SyncableEntity {

  @Column(nullable = false, length = 200)
  private String company;

  @Column(nullable = false, length = 200)
  private String role;

  @Column(length = 200)
  private String location;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  private JobApplicationSource source;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  private JobApplicationStatus status;

  @Column(name = "applied_date")
  private LocalDate appliedDate;

  @Column(columnDefinition = "TEXT")
  private String notes;

  @Column(length = 500)
  private String url;

  public String getCompany() {
    return company;
  }

  public void setCompany(String company) {
    this.company = company;
  }

  public String getRole() {
    return role;
  }

  public void setRole(String role) {
    this.role = role;
  }

  public String getLocation() {
    return location;
  }

  public void setLocation(String location) {
    this.location = location;
  }

  public JobApplicationSource getSource() {
    return source;
  }

  public void setSource(JobApplicationSource source) {
    this.source = source;
  }

  public JobApplicationStatus getStatus() {
    return status;
  }

  public void setStatus(JobApplicationStatus status) {
    this.status = status;
  }

  public LocalDate getAppliedDate() {
    return appliedDate;
  }

  public void setAppliedDate(LocalDate appliedDate) {
    this.appliedDate = appliedDate;
  }

  public String getNotes() {
    return notes;
  }

  public void setNotes(String notes) {
    this.notes = notes;
  }

  public String getUrl() {
    return url;
  }

  public void setUrl(String url) {
    this.url = url;
  }
}
