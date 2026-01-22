// Encapsulates merge rules for offline-first sync to keep behavior predictable.
// This exists so sync logic can be tested independently from data sources.
// It fits in the app by guiding conflict detection and merge outcomes.
import 'sync_status.dart';

enum MergeDecision {
  applyRemote,
  keepLocal,
  conflict,
}

class SyncMergePolicy {
  const SyncMergePolicy();

  MergeDecision decide({
    required SyncStatus localStatus,
    required DateTime localServerUpdatedAt,
    required DateTime remoteServerUpdatedAt,
    required bool localDeleted,
    required bool remoteDeleted,
  }) {
    if (localStatus == SyncStatus.conflict) {
      return MergeDecision.keepLocal;
    }

    if (localStatus == SyncStatus.pending) {
      // Local edits take priority unless the server moved ahead.
      if (remoteServerUpdatedAt.isAfter(localServerUpdatedAt)) {
        return MergeDecision.conflict;
      }
      return MergeDecision.keepLocal;
    }

    if (remoteServerUpdatedAt.isAfter(localServerUpdatedAt)) {
      return MergeDecision.applyRemote;
    }

    // If timestamps match, prefer local to keep UX stable.
    if (remoteDeleted != localDeleted) {
      return MergeDecision.keepLocal;
    }

    return MergeDecision.keepLocal;
  }
}
