package com.focusflow.backend.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Responsibility: Provides a simple health check endpoint. Architecture: API layer entry point for
 * liveness probes. Why: Allows infrastructure to verify the service is running without auth.
 */
@RestController
@RequestMapping("/api/v1/health")
@Tag(name = "Health")
public class HealthController {

  @GetMapping
  @Operation(summary = "Health check", description = "Returns service health status.")
  public Map<String, String> health() {
    return Map.of("status", "ok");
  }
}
