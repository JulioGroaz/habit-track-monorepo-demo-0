package com.focusflow.backend.controller;

import com.focusflow.backend.dto.CheckInRequest;
import com.focusflow.backend.dto.CheckInResponse;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.CheckInMapper;
import com.focusflow.backend.service.CheckInService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.UUID;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Responsibility: Exposes CRUD endpoints for routine check-ins. Architecture: API layer controller
 * delegating to check-in services. Why: Keeps HTTP handling thin while enforcing user ownership via
 * services.
 */
@RestController
@RequestMapping("/api/v1/checkins")
@Tag(name = "Check-ins")
public class CheckInController {

  private final CheckInService checkInService;
  private final CheckInMapper checkInMapper;

  public CheckInController(CheckInService checkInService, CheckInMapper checkInMapper) {
    this.checkInService = checkInService;
    this.checkInMapper = checkInMapper;
  }

  @GetMapping
  @Operation(
      summary = "List check-ins",
      description = "Lists check-ins with optional routine and date filters.")
  @ApiResponse(responseCode = "200", description = "Check-ins returned")
  public Page<CheckInResponse> list(
      @AuthenticationPrincipal User user,
      @Parameter(description = "Filter by routine ID") @RequestParam(required = false)
          UUID routineId,
      @Parameter(description = "Filter start date (inclusive)")
          @RequestParam(required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate startDate,
      @Parameter(description = "Filter end date (inclusive)")
          @RequestParam(required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate endDate,
      @ParameterObject Pageable pageable) {
    return checkInService
        .listCheckIns(user, routineId, startDate, endDate, pageable)
        .map(checkInMapper::toResponse);
  }

  @PostMapping
  @Operation(summary = "Create check-in", description = "Creates a check-in for a routine.")
  @ApiResponse(responseCode = "200", description = "Check-in created")
  public CheckInResponse create(
      @AuthenticationPrincipal User user, @Valid @RequestBody CheckInRequest request) {
    return checkInMapper.toResponse(checkInService.createCheckIn(user, request));
  }

  @PutMapping("/{id}")
  @Operation(summary = "Update check-in", description = "Updates an existing check-in.")
  @ApiResponse(responseCode = "200", description = "Check-in updated")
  public CheckInResponse update(
      @AuthenticationPrincipal User user,
      @PathVariable UUID id,
      @Valid @RequestBody CheckInRequest request) {
    return checkInMapper.toResponse(checkInService.updateCheckIn(user, id, request));
  }

  @DeleteMapping("/{id}")
  @Operation(summary = "Delete check-in", description = "Soft deletes a check-in.")
  @ApiResponse(responseCode = "204", description = "Check-in deleted")
  public ResponseEntity<Void> delete(@AuthenticationPrincipal User user, @PathVariable UUID id) {
    checkInService.deleteCheckIn(user, id);
    return ResponseEntity.noContent().build();
  }
}
