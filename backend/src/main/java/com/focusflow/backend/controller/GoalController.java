package com.focusflow.backend.controller;

import com.focusflow.backend.dto.GoalRequest;
import com.focusflow.backend.dto.GoalResponse;
import com.focusflow.backend.entity.GoalStatus;
import com.focusflow.backend.entity.User;
import com.focusflow.backend.mapper.GoalMapper;
import com.focusflow.backend.service.GoalService;
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
 * Responsibility: Exposes CRUD endpoints for goals. Architecture: Thin API layer delegating to goal
 * services and mappers. Why: Keeps HTTP concerns separate from goal business logic.
 */
@RestController
@RequestMapping("/api/v1/goals")
@Tag(name = "Goals")
public class GoalController {

  private final GoalService goalService;
  private final GoalMapper goalMapper;

  public GoalController(GoalService goalService, GoalMapper goalMapper) {
    this.goalService = goalService;
    this.goalMapper = goalMapper;
  }

  @GetMapping
  @Operation(summary = "List goals", description = "Lists goals for the authenticated user.")
  @ApiResponse(responseCode = "200", description = "Goals returned")
  public Page<GoalResponse> list(
      @AuthenticationPrincipal User user,
      @Parameter(description = "Filter by status") @RequestParam(required = false)
          GoalStatus status,
      @ParameterObject Pageable pageable) {
    return goalService.listGoals(user, status, pageable).map(goalMapper::toResponse);
  }

  @PostMapping
  @Operation(summary = "Create goal", description = "Creates a goal for the authenticated user.")
  @ApiResponse(responseCode = "200", description = "Goal created")
  public GoalResponse create(
      @AuthenticationPrincipal User user, @Valid @RequestBody GoalRequest request) {
    return goalMapper.toResponse(goalService.createGoal(user, request));
  }

  @PutMapping("/{id}")
  @Operation(summary = "Update goal", description = "Updates a goal owned by the user.")
  @ApiResponse(responseCode = "200", description = "Goal updated")
  public GoalResponse update(
      @AuthenticationPrincipal User user,
      @PathVariable UUID id,
      @Valid @RequestBody GoalRequest request) {
    return goalMapper.toResponse(goalService.updateGoal(user, id, request));
  }

  @DeleteMapping("/{id}")
  @Operation(summary = "Delete goal", description = "Soft deletes a goal owned by the user.")
  @ApiResponse(responseCode = "204", description = "Goal deleted")
  public ResponseEntity<Void> delete(@AuthenticationPrincipal User user, @PathVariable UUID id) {
    goalService.deleteGoal(user, id);
    return ResponseEntity.noContent().build();
  }
}
