// DTO for goal API payloads to keep network contracts explicit.
// This exists to isolate transport serialization from domain entities.
// It fits in the app by enabling typed API calls in sync flows.
import '../../../domain/goals/goal.dart';
import '../../../domain/sync/sync_status.dart';

class GoalDto {
  GoalDto({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.targetDate,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
  });

  final String id;
  final String title;
  final String? description;
  final String status;
  final String? targetDate;
  final String clientUpdatedAt;
  final String serverUpdatedAt;
  final bool isDeleted;

  factory GoalDto.fromJson(Map<String, dynamic> json) {
    return GoalDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      targetDate: json['targetDate'] as String?,
      clientUpdatedAt: json['clientUpdatedAt'] as String,
      serverUpdatedAt: json['serverUpdatedAt'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'targetDate': targetDate,
        'clientUpdatedAt': clientUpdatedAt,
        'serverUpdatedAt': serverUpdatedAt,
        'isDeleted': isDeleted,
      };

  Goal toDomain() {
    return Goal(
      id: id,
      title: title,
      description: description,
      status: GoalStatusStorage.fromStorage(status),
      targetDate: targetDate == null ? null : DateTime.parse(targetDate!).toUtc(),
      clientUpdatedAt: DateTime.parse(clientUpdatedAt).toUtc(),
      serverUpdatedAt: DateTime.parse(serverUpdatedAt).toUtc(),
      isDeleted: isDeleted,
      syncStatus: SyncStatus.synced,
    );
  }

  static GoalDto fromDomain(Goal goal) {
    return GoalDto(
      id: goal.id,
      title: goal.title,
      description: goal.description,
      status: goal.status.toStorageString(),
      targetDate: goal.targetDate?.toUtc().toIso8601String(),
      clientUpdatedAt: goal.clientUpdatedAt.toUtc().toIso8601String(),
      serverUpdatedAt: goal.serverUpdatedAt.toUtc().toIso8601String(),
      isDeleted: goal.isDeleted,
    );
  }
}
