package com.focusflow.backend.dto;

import jakarta.validation.Valid;
import java.util.List;

/**
 * Responsibility: Bundles client-side changes for a sync push operation. Architecture: Sync DTO
 * consumed by the sync controller and service. Why: Allows batching cross-entity updates into a
 * single offline sync request.
 */
public record SyncPushRequest(
    @Valid List<GoalSyncRequest> goals,
    @Valid List<RoutineSyncRequest> routines,
    @Valid List<CheckInSyncRequest> checkIns,
    @Valid List<JobApplicationSyncRequest> applications) {}
