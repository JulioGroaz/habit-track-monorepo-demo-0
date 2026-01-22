package com.focusflow.backend.dto;

import java.time.Instant;
import java.util.List;

/**
 * Responsibility: Returns accepted sync updates plus any conflicts. Architecture: Sync response DTO
 * emitted by the sync controller. Why: Gives clients authoritative server versions and conflict
 * details in one payload.
 */
public record SyncPushResponse(
    List<GoalResponse> goals,
    List<RoutineResponse> routines,
    List<CheckInResponse> checkIns,
    List<JobApplicationResponse> applications,
    List<SyncConflict> conflicts,
    Instant serverTime) {}
