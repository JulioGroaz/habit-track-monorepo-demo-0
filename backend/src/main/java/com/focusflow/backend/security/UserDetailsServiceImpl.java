package com.focusflow.backend.security;

import com.focusflow.backend.entity.User;
import com.focusflow.backend.repository.UserRepository;
import java.util.UUID;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * Responsibility: Loads user principals for Spring Security. Architecture: Security adapter
 * bridging repositories and authentication providers. Why: Provides a single source of truth for
 * user lookup by email or ID.
 */
@Service
public class UserDetailsServiceImpl implements UserDetailsService {

  private final UserRepository userRepository;

  public UserDetailsServiceImpl(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  @Override
  public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
    return userRepository
        .findByEmail(username.trim().toLowerCase())
        .orElseThrow(() -> new UsernameNotFoundException("User not found"));
  }

  public User loadUserById(UUID id) {
    return userRepository
        .findById(id)
        .orElseThrow(() -> new UsernameNotFoundException("User not found"));
  }
}
