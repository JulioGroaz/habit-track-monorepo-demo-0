// Goal entity and status definitions for focus planning.
// This exists to keep goal data consistent across data and UI layers.
// It fits in the app by powering the Goals screen and sync engine.
import '../sync/sync_status.dart';

enum GoalStatus {
  active,
  paused,
  completed,
}

extension GoalStatusStorage on GoalStatus {
  String toStorageString() => name.toUpperCase();

  static GoalStatus fromStorage(String value) {
    switch (value.toUpperCase()) {
      case 'PAUSED':
        return GoalStatus.paused;
      case 'COMPLETED':
        return GoalStatus.completed;
      case 'ACTIVE':
      default:
        return GoalStatus.active;
    }
  }

  String get label {
    switch (this) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.paused:
        return 'Paused';
      case GoalStatus.completed:
        return 'Completed';
    }
  }
}

class Goal {
  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.targetDate,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
    required this.syncStatus,
  });

  final String id;
  final String title;
  final String? description;
  final GoalStatus status;
  final DateTime? targetDate;
  final DateTime clientUpdatedAt;
  final DateTime serverUpdatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalStatus? status,
    DateTime? targetDate,
    DateTime? clientUpdatedAt,
    DateTime? serverUpdatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: GoalStatusStorage.fromStorage(json['status'] as String),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String).toUtc(),
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
        'description': description,
        'status': status.toStorageString(),
        'targetDate': targetDate?.toUtc().toIso8601String(),
        'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
        'serverUpdatedAt': serverUpdatedAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
        'syncStatus': syncStatus.toStorageString(),
      };
}
