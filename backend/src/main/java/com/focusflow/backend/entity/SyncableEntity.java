package com.focusflow.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import java.time.Instant;

/**
 * Responsibility: Captures sync metadata for offline-first entities. Architecture: Domain base
 * class for entities participating in the sync pipeline. Why: Centralizes client/server timestamps
 * so sync logic can be consistent across models.
 */
@MappedSuperclass
public abstract class SyncableEntity extends UserOwnedEntity {

  @Column(name = "client_updated_at", nullable = false)
  private Instant clientUpdatedAt;

  @Column(name = "server_updated_at", nullable = false)
  private Instant serverUpdatedAt;

  @PrePersist
  void onSyncCreate() {
    Instant now = Instant.now();
    if (clientUpdatedAt == null) {
      clientUpdatedAt = now;
    }
    if (serverUpdatedAt == null) {
      serverUpdatedAt = now;
    }
  }

  public Instant getClientUpdatedAt() {
    return clientUpdatedAt;
  }

  public void setClientUpdatedAt(Instant clientUpdatedAt) {
    this.clientUpdatedAt = clientUpdatedAt;
  }

  public Instant getServerUpdatedAt() {
    return serverUpdatedAt;
  }

  public void setServerUpdatedAt(Instant serverUpdatedAt) {
    this.serverUpdatedAt = serverUpdatedAt;
  }
}
