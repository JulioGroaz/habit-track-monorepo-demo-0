package com.focusflow.backend.dto;

import java.time.Instant;
import java.util.List;

/**
 * Responsibility: Returns all server-side changes since a given timestamp. Architecture: Sync
 * response DTO for pull operations. Why: Enables offline clients to incrementally hydrate local
 * state.
 */
public record SyncPullResponse(
    List<GoalResponse> goals,
    List<RoutineResponse> routines,
    List<CheckInResponse> checkIns,
    List<JobApplicationResponse> applications,
    Instant serverTime) {}
