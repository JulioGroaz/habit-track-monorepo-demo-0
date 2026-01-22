// Tracks completion of a routine for a specific day for progress calculations.
// This exists to preserve daily checkmarks and sync them across devices.
// It fits in the app by powering dashboard progress and routine checklists.
import '../sync/sync_status.dart';

class RoutineCompletion {
  RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.date,
    required this.completedAt,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
    required this.syncStatus,
  });

  final String id;
  final String routineId;
  final DateTime date;
  final DateTime completedAt;
  final DateTime clientUpdatedAt;
  final DateTime serverUpdatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  RoutineCompletion copyWith({
    String? id,
    String? routineId,
    DateTime? date,
    DateTime? completedAt,
    DateTime? clientUpdatedAt,
    DateTime? serverUpdatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return RoutineCompletion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'date':
            "${date.year.toString().padLeft(4, '0')}-"
            "${date.month.toString().padLeft(2, '0')}-"
            "${date.day.toString().padLeft(2, '0')}",
        'completedAt': completedAt.toUtc().toIso8601String(),
        'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
        'serverUpdatedAt': serverUpdatedAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
        'syncStatus': syncStatus.toStorageString(),
      };
}
