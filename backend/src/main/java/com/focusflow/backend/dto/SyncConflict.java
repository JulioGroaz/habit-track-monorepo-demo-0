package com.focusflow.backend.dto;

import java.util.UUID;

/**
 * Responsibility: Represents a rejected sync change with both client and server versions.
 * Architecture: Sync DTO returned by the sync controller to inform conflict resolution. Why: Makes
 * conflicts explicit so clients can merge without overwriting newer data.
 */
public record SyncConflict(
    String entityType, UUID id, String reason, Object server, Object client) {}
