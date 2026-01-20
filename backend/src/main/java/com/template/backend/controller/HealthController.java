package com.template.backend.controller;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Lightweight health check used for smoke tests and uptime checks. */
@RestController
@RequestMapping("/api")
public class HealthController {

  /** Returns a simple OK payload when the API is reachable. */
  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("status", "ok");
  }
}
