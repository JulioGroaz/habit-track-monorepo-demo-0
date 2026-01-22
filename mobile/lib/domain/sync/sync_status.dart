// Defines sync state for offline-first entities so UI and sync logic stay aligned.
// This exists to keep a single enum for persistence and merge decisions.
// It fits in the app by being referenced by every syncable entity.
enum SyncStatus {
  pending,
  synced,
  conflict,
}

extension SyncStatusStorage on SyncStatus {
  String toStorageString() {
    switch (this) {
      case SyncStatus.pending:
        return 'PENDING';
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.conflict:
        return 'CONFLICT';
    }
  }

  static SyncStatus fromStorage(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return SyncStatus.pending;
      case 'SYNCED':
        return SyncStatus.synced;
      case 'CONFLICT':
        return SyncStatus.conflict;
      default:
        return SyncStatus.pending;
    }
  }
}
