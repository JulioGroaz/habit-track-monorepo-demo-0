// Application entity and enums for tracking job application pipeline.
// This exists to keep application data consistent across layers.
// It fits in the app by powering the Applications screen and sync flow.
import '../sync/sync_status.dart';

enum ApplicationStatus {
  applied,
  interview,
  offer,
  rejected,
}

extension ApplicationStatusStorage on ApplicationStatus {
  String toStorageString() => name.toUpperCase();

  static ApplicationStatus fromStorage(String value) {
    switch (value.toUpperCase()) {
      case 'INTERVIEW':
        return ApplicationStatus.interview;
      case 'OFFER':
        return ApplicationStatus.offer;
      case 'REJECTED':
        return ApplicationStatus.rejected;
      case 'APPLIED':
      default:
        return ApplicationStatus.applied;
    }
  }

  String get label {
    switch (this) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.interview:
        return 'Interview';
      case ApplicationStatus.offer:
        return 'Offer';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}

enum ApplicationSource {
  referral,
  jobBoard,
  companySite,
  recruiter,
  other,
}

extension ApplicationSourceStorage on ApplicationSource {
  String toStorageString() => name.toUpperCase();

  static ApplicationSource fromStorage(String value) {
    switch (value.toUpperCase()) {
      case 'REFERRAL':
        return ApplicationSource.referral;
      case 'COMPANY_SITE':
        return ApplicationSource.companySite;
      case 'RECRUITER':
        return ApplicationSource.recruiter;
      case 'OTHER':
        return ApplicationSource.other;
      case 'JOB_BOARD':
      default:
        return ApplicationSource.jobBoard;
    }
  }

  String get label {
    switch (this) {
      case ApplicationSource.referral:
        return 'Referral';
      case ApplicationSource.jobBoard:
        return 'Job board';
      case ApplicationSource.companySite:
        return 'Company site';
      case ApplicationSource.recruiter:
        return 'Recruiter';
      case ApplicationSource.other:
        return 'Other';
    }
  }
}

class Application {
  Application({
    required this.id,
    required this.company,
    required this.role,
    required this.source,
    required this.status,
    required this.lastUpdatedNote,
    required this.clientUpdatedAt,
    required this.serverUpdatedAt,
    required this.isDeleted,
    required this.syncStatus,
  });

  final String id;
  final String company;
  final String role;
  final ApplicationSource source;
  final ApplicationStatus status;
  final String? lastUpdatedNote;
  final DateTime clientUpdatedAt;
  final DateTime serverUpdatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  Application copyWith({
    String? id,
    String? company,
    String? role,
    ApplicationSource? source,
    ApplicationStatus? status,
    String? lastUpdatedNote,
    DateTime? clientUpdatedAt,
    DateTime? serverUpdatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) {
    return Application(
      id: id ?? this.id,
      company: company ?? this.company,
      role: role ?? this.role,
      source: source ?? this.source,
      status: status ?? this.status,
      lastUpdatedNote: lastUpdatedNote ?? this.lastUpdatedNote,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as String,
      company: json['company'] as String,
      role: json['role'] as String,
      source: ApplicationSourceStorage.fromStorage(json['source'] as String),
      status: ApplicationStatusStorage.fromStorage(json['status'] as String),
      lastUpdatedNote: json['lastUpdatedNote'] as String?,
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
        'company': company,
        'role': role,
        'source': source.toStorageString(),
        'status': status.toStorageString(),
        'lastUpdatedNote': lastUpdatedNote,
        'clientUpdatedAt': clientUpdatedAt.toUtc().toIso8601String(),
        'serverUpdatedAt': serverUpdatedAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
        'syncStatus': syncStatus.toStorageString(),
      };
}
