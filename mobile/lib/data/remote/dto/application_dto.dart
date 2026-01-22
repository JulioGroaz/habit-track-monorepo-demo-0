// DTO for application API payloads to keep network contracts explicit.
// This exists to isolate transport serialization from domain entities.
// It fits in the app by enabling typed API calls in sync flows.
import '../../../domain/applications/application.dart';
import '../../../domain/sync/sync_status.dart';

class ApplicationDto {
  ApplicationDto({
    required this.id,
    required this.company,
    required this.role,
    required this.source,
    required this.status,
    required this.lastUpdatedNote,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
  });

  final String id;
  final String company;
  final String role;
  final String source;
  final String status;
  final String? lastUpdatedNote;
  final String clientUpdatedAt;
  final String serverUpdatedAt;
  final bool isDeleted;

  factory ApplicationDto.fromJson(Map<String, dynamic> json) {
    return ApplicationDto(
      id: json['id'] as String,
      company: json['company'] as String,
      role: json['role'] as String,
      source: json['source'] as String,
      status: json['status'] as String,
      lastUpdatedNote: json['lastUpdatedNote'] as String?,
      clientUpdatedAt: json['clientUpdatedAt'] as String,
      serverUpdatedAt: json['serverUpdatedAt'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company': company,
        'role': role,
        'source': source,
        'status': status,
        'lastUpdatedNote': lastUpdatedNote,
        'clientUpdatedAt': clientUpdatedAt,
        'serverUpdatedAt': serverUpdatedAt,
        'isDeleted': isDeleted,
      };

  Application toDomain() {
    return Application(
      id: id,
      company: company,
      role: role,
      source: ApplicationSourceStorage.fromStorage(source),
      status: ApplicationStatusStorage.fromStorage(status),
      lastUpdatedNote: lastUpdatedNote,
      clientUpdatedAt: DateTime.parse(clientUpdatedAt).toUtc(),
      serverUpdatedAt: DateTime.parse(serverUpdatedAt).toUtc(),
      isDeleted: isDeleted,
      syncStatus: SyncStatus.synced,
    );
  }

  static ApplicationDto fromDomain(Application application) {
    return ApplicationDto(
      id: application.id,
      company: application.company,
      role: application.role,
      source: application.source.toStorageString(),
      status: application.status.toStorageString(),
      lastUpdatedNote: application.lastUpdatedNote,
      clientUpdatedAt: application.clientUpdatedAt.toUtc().toIso8601String(),
      serverUpdatedAt: application.serverUpdatedAt.toUtc().toIso8601String(),
      isDeleted: application.isDeleted,
    );
  }
}
