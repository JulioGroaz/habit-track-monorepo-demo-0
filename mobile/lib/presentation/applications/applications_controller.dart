// Manages application list, filters, and CRUD for the pipeline screen.
// This exists to keep UI logic separated from persistence.
// It fits in the app by powering the Applications tab.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/applications/application.dart';
import '../../domain/applications/application_repository.dart';
import '../../domain/sync/sync_status.dart';

class ApplicationsViewState {
  ApplicationsViewState({
    required this.applications,
    required this.statusFilter,
    required this.sourceFilter,
  });

  final List<Application> applications;
  final ApplicationStatus? statusFilter;
  final ApplicationSource? sourceFilter;
}

class ApplicationsController
    extends StateNotifier<AsyncValue<ApplicationsViewState>> {
  ApplicationsController(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(const AsyncValue.loading()) {
    load();
  }

  final ApplicationRepository _repository;
  final Uuid _uuid;
  ApplicationStatus? _statusFilter;
  ApplicationSource? _sourceFilter;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final applications = await _repository.fetchApplications(
        status: _statusFilter,
        source: _sourceFilter,
      );
      state = AsyncValue.data(
        ApplicationsViewState(
          applications: applications,
          statusFilter: _statusFilter,
          sourceFilter: _sourceFilter,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setStatusFilter(ApplicationStatus? status) async {
    _statusFilter = status;
    await load();
  }

  Future<void> setSourceFilter(ApplicationSource? source) async {
    _sourceFilter = source;
    await load();
  }

  Future<void> createApplication({
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
    await _repository.upsertApplication(application);
    await load();
  }

  Future<void> updateApplication(Application application) async {
    final now = DateTime.now().toUtc();
    final updated = application.copyWith(
      clientUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    await _repository.upsertApplication(updated);
    await load();
  }

  Future<void> deleteApplication(String id) async {
    await _repository.markApplicationDeleted(id);
    await load();
  }
}

final applicationsControllerProvider = StateNotifierProvider<
    ApplicationsController, AsyncValue<ApplicationsViewState>>((ref) {
  return ApplicationsController(ref.read(applicationRepositoryProvider));
});
