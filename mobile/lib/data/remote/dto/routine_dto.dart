// DTO for routine API payloads to keep network contracts explicit.
// This exists to isolate transport serialization from domain entities.
// It fits in the app by enabling typed API calls in sync flows.
import '../../../domain/routines/routine.dart';
import '../../../domain/sync/sync_status.dart';

class RoutineDto {
  RoutineDto({
    required this.id,
    required this.title,
    required this.notes,
    required this.activeDays,
    required this.isActive,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
  });

  final String id;
  final String title;
  final String? notes;
  final List<int> activeDays;
  final bool isActive;
  final String clientUpdatedAt;
  final String serverUpdatedAt;
  final bool isDeleted;

  factory RoutineDto.fromJson(Map<String, dynamic> json) {
    return RoutineDto(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      activeDays: (json['activeDays'] as List<dynamic>? ?? const [])
          .map((entry) => entry as int)
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      clientUpdatedAt: json['clientUpdatedAt'] as String,
      serverUpdatedAt: json['serverUpdatedAt'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'activeDays': activeDays,
        'isActive': isActive,
        'clientUpdatedAt': clientUpdatedAt,
        'serverUpdatedAt': serverUpdatedAt,
        'isDeleted': isDeleted,
      };

  Routine toDomain() {
    return Routine(
      id: id,
      title: title,
      notes: notes,
      activeDays: activeDays,
      isActive: isActive,
      clientUpdatedAt: DateTime.parse(clientUpdatedAt).toUtc(),
      serverUpdatedAt: DateTime.parse(serverUpdatedAt).toUtc(),
      isDeleted: isDeleted,
      syncStatus: SyncStatus.synced,
    );
  }

  static RoutineDto fromDomain(Routine routine) {
    return RoutineDto(
      id: routine.id,
      title: routine.title,
      notes: routine.notes,
      activeDays: routine.activeDays,
      isActive: routine.isActive,
      clientUpdatedAt: routine.clientUpdatedAt.toUtc().toIso8601String(),
      serverUpdatedAt: routine.serverUpdatedAt.toUtc().toIso8601String(),
      isDeleted: routine.isDeleted,
    );
  }
}
