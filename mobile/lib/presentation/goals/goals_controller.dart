// Manages goal list state, filters, and CRUD actions for the Goals screen.
// This exists to keep UI logic separate from persistence concerns.
// It fits in the app by powering filtering and list updates.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/goals/goal.dart';
import '../../domain/goals/goal_repository.dart';
import '../../domain/sync/sync_status.dart';

class GoalsViewState {
  GoalsViewState({
    required this.goals,
    required this.filter,
  });

  final List<Goal> goals;
  final GoalStatus? filter;
}

class GoalsController extends StateNotifier<AsyncValue<GoalsViewState>> {
  GoalsController(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(const AsyncValue.loading()) {
    load();
  }

  final GoalRepository _repository;
  final Uuid _uuid;
  GoalStatus? _filter;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.fetchGoals(status: _filter);
      state = AsyncValue.data(GoalsViewState(goals: goals, filter: _filter));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setFilter(GoalStatus? status) async {
    _filter = status;
    await load();
  }

  Future<void> createGoal({
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
    await _repository.upsertGoal(goal);
    await load();
  }

  Future<void> updateGoal(Goal goal) async {
    final now = DateTime.now().toUtc();
    final updated = goal.copyWith(
      clientUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    await _repository.upsertGoal(updated);
    await load();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.markGoalDeleted(id);
    await load();
  }
}

final goalsControllerProvider =
    StateNotifierProvider<GoalsController, AsyncValue<GoalsViewState>>((ref) {
  return GoalsController(ref.read(goalRepositoryProvider));
});
