package com.focusflow.backend.entity;

import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MappedSuperclass;
import java.util.UUID;

/**
 * Responsibility: Adds ownership semantics for user-scoped domain entities. Architecture: Domain
 * base class that sits between audit support and concrete entities. Why: Guarantees every
 * user-owned record has a consistent user_id column and association.
 */
@MappedSuperclass
public abstract class UserOwnedEntity extends AuditableEntity {

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "user_id", nullable = false)
  private User owner;

  public User getOwner() {
    return owner;
  }

  public void setOwner(User owner) {
    this.owner = owner;
  }

  public UUID getUserId() {
    return owner != null ? owner.getId() : null;
  }
}
