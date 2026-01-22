// Implements routine persistence and checklist behavior using AppDatabase.
// This exists to enforce offline-first updates for routines and completions.
// It fits in the app by powering the Routines screen and dashboard checklist.
import 'package:uuid/uuid.dart';

import '../../domain/routines/routine.dart';
import '../../domain/routines/routine_checklist_item.dart';
import '../../domain/routines/routine_completion.dart';
import '../../domain/routines/routine_repository.dart';
import '../../domain/sync/sync_status.dart';
import '../db/app_database.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  RoutineRepositoryImpl(this._database, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Future<List<Routine>> fetchRoutines({bool includeDeleted = false}) {
    return _database.fetchRoutines(includeDeleted: includeDeleted);
  }

  @override
  Future<void> upsertRoutine(Routine routine) {
    return _database.upsertRoutine(routine);
  }

  @override
  Future<void> markRoutineDeleted(String id) async {
    final existing = await _database.fetchRoutineById(id);
    if (existing == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final updated = existing.copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pending,
      clientUpdatedAt: now,
    );
    await _database.upsertRoutine(updated);
  }

  @override
  Future<List<RoutineCompletion>> fetchCompletionsForRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _database.fetchCompletionsForRange(start: start, end: end);
  }

  @override
  Future<List<RoutineCompletion>> fetchCompletionsForDay(DateTime day) {
    return _database.fetchCompletionsForDay(day);
  }

  @override
  Future<List<RoutineChecklistItem>> fetchChecklist(DateTime day) async {
    final routines = await _database.fetchRoutines();
    final completions = await _database.fetchCompletionsForDay(day);
    final completedIds = completions
        .where((entry) => !entry.isDeleted)
        .map((entry) => entry.routineId)
        .toSet();

    return routines
        .where((routine) => routine.isActive)
        .where((routine) =>
            routine.activeDays.isEmpty ||
            routine.activeDays.contains(day.weekday))
        .map(
          (routine) => RoutineChecklistItem(
            routine: routine,
            isCompleted: completedIds.contains(routine.id),
          ),
        )
        .toList();
  }

  @override
  Future<void> toggleCompletion({
    required String routineId,
    required DateTime day,
    required bool isCompleted,
  }) async {
    final now = DateTime.now().toUtc();
    final completions = await _database.fetchCompletionsForDay(day);
    RoutineCompletion? existing;
    for (final entry in completions) {
      if (entry.routineId == routineId) {
        existing = entry;
        break;
      }
    }

    if (isCompleted) {
      if (existing == null) {
        final completion = RoutineCompletion(
          id: _uuid.v4(),
          routineId: routineId,
          date: day,
          completedAt: now,
          clientUpdatedAt: now,
          serverUpdatedAt: now,
          isDeleted: false,
          syncStatus: SyncStatus.pending,
        );
        await _database.upsertCompletion(completion);
        return;
      }

      final updated = existing.copyWith(
        completedAt: now,
        isDeleted: false,
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: now,
      );
      await _database.upsertCompletion(updated);
      return;
    }

    if (existing != null && !existing.isDeleted) {
      final updated = existing.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: now,
      );
      await _database.upsertCompletion(updated);
    }
  }
}
