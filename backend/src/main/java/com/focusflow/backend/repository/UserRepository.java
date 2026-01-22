package com.focusflow.backend.repository;

import com.focusflow.backend.entity.User;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Responsibility: Data access for user identities. Architecture: Repository layer boundary for the
 * user aggregate. Why: Keeps persistence concerns out of authentication services.
 */
public interface UserRepository extends JpaRepository<User, UUID> {
  Optional<User> findByEmail(String email);

  boolean existsByEmail(String email);
}
