// Implements application persistence with offline-first semantics.
// This exists to keep application CRUD behavior consistent for sync.
// It fits in the app by backing the Applications UI.
import 'package:uuid/uuid.dart';

import '../../domain/applications/application.dart';
import '../../domain/applications/application_repository.dart';
import '../../domain/sync/sync_status.dart';
import '../db/app_database.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  ApplicationRepositoryImpl(this._database, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Future<List<Application>> fetchApplications({
    ApplicationStatus? status,
    ApplicationSource? source,
    bool includeDeleted = false,
  }) {
    return _database.fetchApplications(
      status: status,
      source: source,
      includeDeleted: includeDeleted,
    );
  }

  @override
  Future<Application?> fetchApplicationById(String id) {
    return _database.fetchApplicationById(id);
  }

  @override
  Future<void> upsertApplication(Application application) {
    return _database.upsertApplication(application);
  }

  @override
  Future<void> markApplicationDeleted(String id) async {
    final existing = await _database.fetchApplicationById(id);
    if (existing == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final updated = existing.copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pending,
      clientUpdatedAt: now,
    );
    await _database.upsertApplication(updated);
  }

  Future<Application> createApplication({
    required String company,
    required String role,
    required ApplicationSource source,
    required ApplicationStatus status,
    String? lastUpdatedNote,
  }) async {
    final now = DateTime.now().toUtc();
    final application = Application(
      id: _uuid.v4(),
      company: company,
      role: role,
      source: source,
      status: status,
      lastUpdatedNote: lastUpdatedNote,
      clientUpdatedAt: now,
      serverUpdatedAt: now,
      isDeleted: false,
      syncStatus: SyncStatus.pending,
    );
    await _database.upsertApplication(application);
    return application;
  }
}
