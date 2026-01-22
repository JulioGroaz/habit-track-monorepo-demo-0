package com.focusflow.backend.controller;

import com.focusflow.backend.dto.SyncPullResponse;
import com.focusflow.backend.dto.SyncPushRequest;
import com.focusflow.backend.dto.SyncPushResponse;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.service.SyncService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Instant;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Responsibility: Exposes offline sync push/pull endpoints. Architecture: API layer controller
 * delegating sync workflows to SyncService. Why: Keeps sync HTTP surface thin while enforcing
 * security context ownership.
 */
@RestController
@RequestMapping("/api/v1/sync")
@Tag(name = "Sync")
public class SyncController {

  private final SyncService syncService;

  public SyncController(SyncService syncService) {
    this.syncService = syncService;
  }

  @PostMapping("/push")
  @Operation(
      summary = "Sync push",
      description = "Pushes client changes and returns accepted updates plus conflicts.")
  @ApiResponse(responseCode = "200", description = "Sync push processed")
  public SyncPushResponse push(
      @AuthenticationPrincipal User user, @Valid @RequestBody SyncPushRequest request) {
    return syncService.push(user, request);
  }

  @GetMapping("/pull")
  @Operation(
      summary = "Sync pull",
      description = "Pulls server changes since the provided timestamp.")
  @ApiResponse(responseCode = "200", description = "Sync pull returned")
  public SyncPullResponse pull(
      @AuthenticationPrincipal User user,
      @Parameter(description = "ISO-8601 timestamp for incremental sync")
          @RequestParam(required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
          Instant since) {
    return syncService.pull(user, since);
  }
}
