// Routine entity defines recurring habits and their weekly schedules.
// This exists to keep routine data consistent across data and UI layers.
// It fits in the app by powering routines setup and daily checklists.
import '../sync/sync_status.dart';

class Routine {
  Routine({
    required this.id,
    required this.title,
    required this.notes,
    required this.activeDays,
    required this.isActive,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
    required this.syncStatus,
  });

  final String id;
  final String title;
  final String? notes;
  final List<int> activeDays;
  final bool isActive;
  final DateTime clientUpdatedAt;
  final DateTime serverUpdatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  Routine copyWith({
    String? id,
    String? title,
    String? notes,
    List<int>? activeDays,
    bool? isActive,
    DateTime? clientUpdatedAt,
    DateTime? serverUpdatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      activeDays: activeDays ?? this.activeDays,
      isActive: isActive ?? this.isActive,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      activeDays: (json['activeDays'] as List<dynamic>? ?? const [])
          .map((value) => value as int)
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      clientUpdatedAt:
          DateTime.parse(json['clientUpdatedAt'] as String).toUtc(),
      serverUpdatedAt:
          DateTime.parse(json['serverUpdatedAt'] as String).toUtc(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      syncStatus:
          SyncStatusStorage.fromStorage(json['syncStatus'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'activeDays': activeDays,
        'isActive': isActive,
        'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
        'serverUpdatedAt': serverUpdatedAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
        'syncStatus': syncStatus.toStorageString(),
      };
}
