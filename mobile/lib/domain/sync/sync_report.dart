// Represents a sync run summary so UI can show status and diagnostics.
// This exists to carry counts for pushed/pulled/conflicted entities.
// It fits in the app by informing the Dashboard sync indicator.
class SyncReport {
  SyncReport({
    required this.startedAt,
    required this.finishedAt,
    required this.pushed,
    required this.pulled,
    required this.conflicts,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final int pushed;
  final int pulled;
  final int conflicts;
}
