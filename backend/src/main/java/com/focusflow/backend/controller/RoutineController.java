package com.focusflow.backend.controller;

import com.focusflow.backend.dto.RoutineRequest;
import com.focusflow.backend.dto.RoutineResponse;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.RoutineMapper;
import com.focusflow.backend.service.RoutineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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
 * Responsibility: Exposes CRUD endpoints for routines. Architecture: API layer controller
 * delegating routine logic to services. Why: Keeps HTTP concerns separate from routine scheduling
 * logic.
 */
@RestController
@RequestMapping("/api/v1/routines")
@Tag(name = "Routines")
public class RoutineController {

  private final RoutineService routineService;
  private final RoutineMapper routineMapper;

  public RoutineController(RoutineService routineService, RoutineMapper routineMapper) {
    this.routineService = routineService;
    this.routineMapper = routineMapper;
  }

  @GetMapping
  @Operation(
      summary = "List routines",
      description = "Lists routines for the authenticated user with optional filtering.")
  @ApiResponse(responseCode = "200", description = "Routines returned")
  public Page<RoutineResponse> list(
      @AuthenticationPrincipal User user,
      @Parameter(description = "Filter by active flag") @RequestParam(required = false)
          Boolean active,
      @ParameterObject Pageable pageable) {
    return routineService.listRoutines(user, active, pageable).map(routineMapper::toResponse);
  }

  @PostMapping
  @Operation(summary = "Create routine", description = "Creates a routine for the user.")
  @ApiResponse(responseCode = "200", description = "Routine created")
  public RoutineResponse create(
      @AuthenticationPrincipal User user, @Valid @RequestBody RoutineRequest request) {
    return routineMapper.toResponse(routineService.createRoutine(user, request));
  }

  @PutMapping("/{id}")
  @Operation(summary = "Update routine", description = "Updates a routine owned by the user.")
  @ApiResponse(responseCode = "200", description = "Routine updated")
  public RoutineResponse update(
      @AuthenticationPrincipal User user,
      @PathVariable UUID id,
      @Valid @RequestBody RoutineRequest request) {
    return routineMapper.toResponse(routineService.updateRoutine(user, id, request));
  }

  @DeleteMapping("/{id}")
  @Operation(summary = "Delete routine", description = "Soft deletes a routine owned by the user.")
  @ApiResponse(responseCode = "204", description = "Routine deleted")
  public ResponseEntity<Void> delete(@AuthenticationPrincipal User user, @PathVariable UUID id) {
    routineService.deleteRoutine(user, id);
    return ResponseEntity.noContent().build();
  }
}
