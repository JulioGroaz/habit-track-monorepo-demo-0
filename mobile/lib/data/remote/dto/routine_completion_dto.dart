// DTO for routine completion API payloads to keep network contracts explicit.
// This exists to isolate transport serialization from domain entities.
// It fits in the app by enabling typed API calls in sync flows.
import '../../../domain/routines/routine_completion.dart';
import '../../../domain/sync/sync_status.dart';

class RoutineCompletionDto {
  RoutineCompletionDto({
    required this.id,
    required this.routineId,
    required this.date,
    required this.completedAt,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
  });

  final String id;
  final String routineId;
  final String date;
  final String completedAt;
  final String clientUpdatedAt;
  final String serverUpdatedAt;
  final bool isDeleted;

  factory RoutineCompletionDto.fromJson(Map<String, dynamic> json) {
    return RoutineCompletionDto(
      id: json['id'] as String,
      routineId: json['routineId'] as String,
      date: json['date'] as String,
      completedAt: json['completedAt'] as String,
      clientUpdatedAt: json['clientUpdatedAt'] as String,
      serverUpdatedAt: json['serverUpdatedAt'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routineId': routineId,
        'date': date,
        'completedAt': completedAt,
        'clientUpdatedAt': clientUpdatedAt,
        'serverUpdatedAt': serverUpdatedAt,
        'isDeleted': isDeleted,
      };

  RoutineCompletion toDomain() {
    return RoutineCompletion(
      id: id,
      routineId: routineId,
      date: DateTime.parse(date),
      completedAt: DateTime.parse(completedAt).toUtc(),
      clientUpdatedAt: DateTime.parse(clientUpdatedAt).toUtc(),
      serverUpdatedAt: DateTime.parse(serverUpdatedAt).toUtc(),
      isDeleted: isDeleted,
      syncStatus: SyncStatus.synced,
    );
  }

  static RoutineCompletionDto fromDomain(RoutineCompletion completion) {
    final dateOnly =
        "${completion.date.year.toString().padLeft(4, '0')}-"
        "${completion.date.month.toString().padLeft(2, '0')}-"
        "${completion.date.day.toString().padLeft(2, '0')}";
    return RoutineCompletionDto(
      id: completion.id,
      routineId: completion.routineId,
      date: dateOnly,
      completedAt: completion.completedAt.toUtc().toIso8601String(),
      clientUpdatedAt: completion.clientUpdatedAt.toUtc().toIso8601String(),
      serverUpdatedAt: completion.serverUpdatedAt.toUtc().toIso8601String(),
      isDeleted: completion.isDeleted,
    );
  }
}
