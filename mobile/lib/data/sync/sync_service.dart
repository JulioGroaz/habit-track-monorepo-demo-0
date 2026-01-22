// Orchestrates offline-first synchronization between local DB and the backend.
// This exists to implement the push/conflict/pull workflow in one place.
// It fits in the app by powering auto-sync on start, refresh, and connectivity.
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/storage/secure_storage.dart';
import '../../domain/applications/application.dart';
import '../../domain/goals/goal.dart';
import '../../domain/routines/routine.dart';
import '../../domain/routines/routine_completion.dart';
import '../../domain/sync/conflict_record.dart';
import '../../domain/sync/sync_merge_policy.dart';
import '../../domain/sync/sync_report.dart';
import '../../domain/sync/sync_status.dart';
import '../db/app_database.dart';
import '../remote/application_api.dart';
import '../remote/dto/application_dto.dart';
import '../remote/dto/goal_dto.dart';
import '../remote/dto/routine_completion_dto.dart';
import '../remote/dto/routine_dto.dart';
import '../remote/goal_api.dart';
import '../remote/routine_api.dart';
import '../../core/network/api_exception.dart';

class SyncService {
  SyncService({
    required AppDatabase database,
    required GoalApi goalApi,
    required RoutineApi routineApi,
    required ApplicationApi applicationApi,
    required TokenStorage tokenStorage,
    SyncMergePolicy? mergePolicy,
    Uuid? uuid,
  })  : _database = database,
        _goalApi = goalApi,
        _routineApi = routineApi,
        _applicationApi = applicationApi,
        _tokenStorage = tokenStorage,
        _mergePolicy = mergePolicy ?? const SyncMergePolicy(),
        _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final GoalApi _goalApi;
  final RoutineApi _routineApi;
  final ApplicationApi _applicationApi;
  final TokenStorage _tokenStorage;
  final SyncMergePolicy _mergePolicy;
  final Uuid _uuid;
  bool _isSyncing = false;

  Future<SyncReport> syncAll() async {
    if (_isSyncing) {
      final now = DateTime.now().toUtc();
      return SyncReport(
        startedAt: now,
        finishedAt: now,
        pushed: 0,
        pulled: 0,
        conflicts: 0,
      );
    }

    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      final now = DateTime.now().toUtc();
      return SyncReport(
        startedAt: now,
        finishedAt: now,
        pushed: 0,
        pulled: 0,
        conflicts: 0,
      );
    }

    _isSyncing = true;
    final startedAt = DateTime.now().toUtc();
    var pushed = 0;
    var pulled = 0;
    var conflicts = 0;

    try {
      // Offline-first contract: local changes go up before we pull new server state.
      pushed += await _pushGoals();
      pushed += await _pushRoutines();
      pushed += await _pushRoutineCompletions();
      pushed += await _pushApplications();

      final lastSyncAt = await _database.fetchLastSyncAt();
      // Pull remote changes after push to reduce conflict risk.
      pulled += await _pullGoals(lastSyncAt);
      pulled += await _pullRoutines(lastSyncAt);
      pulled += await _pullRoutineCompletions(lastSyncAt);
      pulled += await _pullApplications(lastSyncAt);

      await _database.setLastSyncAt(DateTime.now().toUtc());
    } finally {
      _isSyncing = false;
    }

    final finishedAt = DateTime.now().toUtc();
    conflicts = await _database.countConflicts();

    return SyncReport(
      startedAt: startedAt,
      finishedAt: finishedAt,
      pushed: pushed,
      pulled: pulled,
      conflicts: conflicts,
    );
  }

  Future<int> _pushGoals() async {
    final pending = await _database.fetchGoals(
      syncStatus: SyncStatus.pending,
      includeDeleted: true,
    );
    var count = 0;

    for (final goal in pending) {
      try {
        if (goal.isDeleted) {
          await _goalApi.delete(
            goal.id,
            goal.clientUpdatedAt.toUtc().toIso8601String(),
          );
          final synced = goal.copyWith(syncStatus: SyncStatus.synced);
          await _database.upsertGoal(synced);
          count++;
          continue;
        }

        final response = await _goalApi.upsert(GoalDto.fromDomain(goal));
        final synced = response.toDomain().copyWith(syncStatus: SyncStatus.synced);
        await _database.upsertGoal(synced);
        count++;
      } on ApiException catch (error) {
        if (error.isConflict) {
          await _handleGoalConflict(goal, error);
          continue;
        }
        rethrow;
      }
    }

    return count;
  }

  Future<int> _pushRoutines() async {
    final pending = await _database.fetchRoutines(
      syncStatus: SyncStatus.pending,
      includeDeleted: true,
    );
    var count = 0;

    for (final routine in pending) {
      try {
        if (routine.isDeleted) {
          await _routineApi.deleteRoutine(
            routine.id,
            routine.clientUpdatedAt.toUtc().toIso8601String(),
          );
          final synced = routine.copyWith(syncStatus: SyncStatus.synced);
          await _database.upsertRoutine(synced);
          count++;
          continue;
        }

        final response = await _routineApi.upsertRoutine(
          RoutineDto.fromDomain(routine),
        );
        final synced =
            response.toDomain().copyWith(syncStatus: SyncStatus.synced);
        await _database.upsertRoutine(synced);
        count++;
      } on ApiException catch (error) {
        if (error.isConflict) {
          await _handleRoutineConflict(routine, error);
          continue;
        }
        rethrow;
      }
    }

    return count;
  }

  Future<int> _pushRoutineCompletions() async {
    final pendingItems =
        await _database.fetchCompletionsBySyncStatus(SyncStatus.pending);
    var count = 0;

    for (final completion in pendingItems) {
      try {
        if (completion.isDeleted) {
          await _routineApi.deleteCompletion(
            completion.id,
            completion.clientUpdatedAt.toUtc().toIso8601String(),
          );
          final synced = completion.copyWith(syncStatus: SyncStatus.synced);
          await _database.upsertCompletion(synced);
          count++;
          continue;
        }

        final response = await _routineApi.upsertCompletion(
          RoutineCompletionDto.fromDomain(completion),
        );
        final synced =
            response.toDomain().copyWith(syncStatus: SyncStatus.synced);
        await _database.upsertCompletion(synced);
        count++;
      } on ApiException catch (error) {
        if (error.isConflict) {
          await _handleCompletionConflict(completion, error);
          continue;
        }
        rethrow;
      }
    }

    return count;
  }

  Future<int> _pushApplications() async {
    final pending = await _database.fetchApplications(
      syncStatus: SyncStatus.pending,
      includeDeleted: true,
    );
    var count = 0;

    for (final application in pending) {
      try {
        if (application.isDeleted) {
          await _applicationApi.delete(
            application.id,
            application.clientUpdatedAt.toUtc().toIso8601String(),
          );
          final synced = application.copyWith(syncStatus: SyncStatus.synced);
          await _database.upsertApplication(synced);
          count++;
          continue;
        }

        final response =
            await _applicationApi.upsert(ApplicationDto.fromDomain(application));
        final synced =
            response.toDomain().copyWith(syncStatus: SyncStatus.synced);
        await _database.upsertApplication(synced);
        count++;
      } on ApiException catch (error) {
        if (error.isConflict) {
          await _handleApplicationConflict(application, error);
          continue;
        }
        rethrow;
      }
    }

    return count;
  }

  Future<int> _pullGoals(DateTime? lastSyncAt) async {
    final remote = await _goalApi.fetchUpdatedSince(lastSyncAt);
    var count = 0;

    for (final dto in remote) {
      final incoming = dto.toDomain();
      final local = await _database.fetchGoalById(incoming.id);
      final decision = _decideMerge(local, incoming);

      if (decision == MergeDecision.applyRemote) {
        await _database.upsertGoal(incoming.copyWith(syncStatus: SyncStatus.synced));
        count++;
      } else if (decision == MergeDecision.conflict && local != null) {
        await _storeConflict('goal', local.toJson(), dto.toJson());
        final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
        await _database.upsertGoal(conflicted);
      }
    }

    return count;
  }

  Future<int> _pullRoutines(DateTime? lastSyncAt) async {
    final remote = await _routineApi.fetchRoutinesUpdatedSince(lastSyncAt);
    var count = 0;

    for (final dto in remote) {
      final incoming = dto.toDomain();
      final local = await _database.fetchRoutineById(incoming.id);
      final decision = _decideMerge(local, incoming);

      if (decision == MergeDecision.applyRemote) {
        await _database.upsertRoutine(incoming.copyWith(syncStatus: SyncStatus.synced));
        count++;
      } else if (decision == MergeDecision.conflict && local != null) {
        await _storeConflict('routine', local.toJson(), dto.toJson());
        final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
        await _database.upsertRoutine(conflicted);
      }
    }

    return count;
  }

  Future<int> _pullRoutineCompletions(DateTime? lastSyncAt) async {
    final remote = await _routineApi.fetchCompletionsUpdatedSince(lastSyncAt);
    var count = 0;

    for (final dto in remote) {
      final incoming = dto.toDomain();
      final local = await _database.fetchCompletionById(incoming.id);
      final decision = _decideMerge(local, incoming);

      if (decision == MergeDecision.applyRemote) {
        await _database.upsertCompletion(incoming.copyWith(syncStatus: SyncStatus.synced));
        count++;
      } else if (decision == MergeDecision.conflict && local != null) {
        await _storeConflict(
          'routine_completion',
          local.toJson(),
          dto.toJson(),
        );
        final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
        await _database.upsertCompletion(conflicted);
      }
    }

    return count;
  }

  Future<int> _pullApplications(DateTime? lastSyncAt) async {
    final remote = await _applicationApi.fetchUpdatedSince(lastSyncAt);
    var count = 0;

    for (final dto in remote) {
      final incoming = dto.toDomain();
      final local = await _database.fetchApplicationById(incoming.id);
      final decision = _decideMerge(local, incoming);

      if (decision == MergeDecision.applyRemote) {
        await _database.upsertApplication(incoming.copyWith(syncStatus: SyncStatus.synced));
        count++;
      } else if (decision == MergeDecision.conflict && local != null) {
        await _storeConflict('application', local.toJson(), dto.toJson());
        final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
        await _database.upsertApplication(conflicted);
      }
    }

    return count;
  }

  MergeDecision _decideMerge<T>(T? local, T remote) {
    if (local == null) {
      return MergeDecision.applyRemote;
    }

    if (local is Goal && remote is Goal) {
      return _mergeDecision(
        local.syncStatus,
        local.serverUpdatedAt,
        remote.serverUpdatedAt,
        local.isDeleted,
        remote.isDeleted,
      );
    }
    if (local is Routine && remote is Routine) {
      return _mergeDecision(
        local.syncStatus,
        local.serverUpdatedAt,
        remote.serverUpdatedAt,
        local.isDeleted,
        remote.isDeleted,
      );
    }
    if (local is RoutineCompletion && remote is RoutineCompletion) {
      return _mergeDecision(
        local.syncStatus,
        local.serverUpdatedAt,
        remote.serverUpdatedAt,
        local.isDeleted,
        remote.isDeleted,
      );
    }
    if (local is Application && remote is Application) {
      return _mergeDecision(
        local.syncStatus,
        local.serverUpdatedAt,
        remote.serverUpdatedAt,
        local.isDeleted,
        remote.isDeleted,
      );
    }

    return MergeDecision.keepLocal;
  }

  MergeDecision _mergeDecision(
    SyncStatus localStatus,
    DateTime localServerUpdatedAt,
    DateTime remoteServerUpdatedAt,
    bool localDeleted,
    bool remoteDeleted,
  ) {
    return _mergePolicy.decide(
      localStatus: localStatus,
      localServerUpdatedAt: localServerUpdatedAt,
      remoteServerUpdatedAt: remoteServerUpdatedAt,
      localDeleted: localDeleted,
      remoteDeleted: remoteDeleted,
    );
  }

  Future<void> _handleGoalConflict(Goal local, ApiException error) async {
    final server = _extractServerPayload(error.payload);
    await _storeConflict('goal', local.toJson(), server ?? {});
    final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
    await _database.upsertGoal(conflicted);
  }

  Future<void> _handleRoutineConflict(Routine local, ApiException error) async {
    final server = _extractServerPayload(error.payload);
    await _storeConflict('routine', local.toJson(), server ?? {});
    final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
    await _database.upsertRoutine(conflicted);
  }

  Future<void> _handleCompletionConflict(
    RoutineCompletion local,
    ApiException error,
  ) async {
    final server = _extractServerPayload(error.payload);
    await _storeConflict('routine_completion', local.toJson(), server ?? {});
    final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
    await _database.upsertCompletion(conflicted);
  }

  Future<void> _handleApplicationConflict(
    Application local,
    ApiException error,
  ) async {
    final server = _extractServerPayload(error.payload);
    await _storeConflict('application', local.toJson(), server ?? {});
    final conflicted = local.copyWith(syncStatus: SyncStatus.conflict);
    await _database.upsertApplication(conflicted);
  }

  Future<void> _storeConflict(
    String entityType,
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) async {
    final record = ConflictRecord(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: local['id'] as String? ?? '',
      localSnapshot: jsonEncode(local),
      remoteSnapshot: jsonEncode(remote),
      createdAt: DateTime.now().toUtc(),
    );
    await _database.insertConflict(record);
  }

  Map<String, dynamic>? _extractServerPayload(Map<String, dynamic>? payload) {
    if (payload == null) {
      return null;
    }
    final server = payload['server'];
    if (server is Map<String, dynamic>) {
      return server;
    }
    return payload;
  }
}
