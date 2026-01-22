// Handles local goal CRUD with offline-first semantics using AppDatabase.
// This exists to keep goal persistence consistent and ready for sync.
// It fits in the app by backing the Goals UI and sync push logic.
import 'package:uuid/uuid.dart';

import '../../domain/goals/goal.dart';
import '../../domain/goals/goal_repository.dart';
import '../../domain/sync/sync_status.dart';
import '../db/app_database.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._database, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Future<List<Goal>> fetchGoals({
    GoalStatus? status,
    bool includeDeleted = false,
  }) {
    return _database.fetchGoals(
      status: status,
      includeDeleted: includeDeleted,
    );
  }

  @override
  Future<Goal?> fetchGoalById(String id) => _database.fetchGoalById(id);

  @override
  Future<void> upsertGoal(Goal goal) {
    return _database.upsertGoal(goal);
  }

  @override
  Future<void> markGoalDeleted(String id) async {
    final existing = await _database.fetchGoalById(id);
    if (existing == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final updated = existing.copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pending,
      clientUpdatedAt: now,
    );
    await _database.upsertGoal(updated);
  }

  @override
  Future<List<Goal>> fetchGoalsBySyncStatus(SyncStatus status) {
    return _database.fetchGoals(syncStatus: status, includeDeleted: true);
  }

  Future<Goal> createGoal({
    required String title,
    String? description,
    GoalStatus status = GoalStatus.active,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now().toUtc();
    final goal = Goal(
      id: _uuid.v4(),
      title: title,
      description: description,
      status: status,
      targetDate: targetDate,
      clientUpdatedAt: now,
      serverUpdatedAt: now,
      isDeleted: false,
      syncStatus: SyncStatus.pending,
    );
    await _database.upsertGoal(goal);
    return goal;
  }
}
