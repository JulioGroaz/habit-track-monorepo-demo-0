package com.focusflow.backend.config;

import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Responsibility: Exposes time utilities as injectable beans. Architecture: Configuration layer
 * supplying cross-cutting infrastructure. Why: Enables deterministic testing of time-based logic
 * like sync timestamps.
 */
@Configuration
public class TimeConfig {

  @Bean
  public Clock systemClock() {
    return Clock.systemUTC();
  }
}
