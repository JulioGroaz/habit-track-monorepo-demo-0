// Represents a sync conflict snapshot so we can surface it to the user later.
// This exists to persist both local and remote versions for manual resolution.
// It fits in the app by powering the Dashboard conflict banner and drill-in UI.
class ConflictRecord {
  ConflictRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localSnapshot,
    required this.remoteSnapshot,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String localSnapshot;
  final String remoteSnapshot;
  final DateTime createdAt;
}
