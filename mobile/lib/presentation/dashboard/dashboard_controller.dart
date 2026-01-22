// Builds the dashboard view model by composing routines, sync, and progress data.
// This exists to keep dashboard UI lightweight and data-driven.
// It fits in the app by powering the main overview experience.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/routines/routine_checklist_item.dart';
import '../../domain/routines/routine_repository.dart';
import '../sync/sync_controller.dart';

class DashboardViewModel {
  DashboardViewModel({
    required this.today,
    required this.checklist,
    required this.weeklyProgress,
    required this.pendingCount,
    required this.conflictCount,
    required this.lastSyncAt,
    required this.isSyncing,
  });

  final DateTime today;
  final List<RoutineChecklistItem> checklist;
  final double weeklyProgress;
  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSyncAt;
  final bool isSyncing;
}

class DashboardController extends StateNotifier<AsyncValue<DashboardViewModel>> {
  DashboardController(this._routines, this._database, this._ref)
      : super(const AsyncValue.loading()) {
    load();
  }

  final RoutineRepository _routines;
  final AppDatabase _database;
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final checklist = await _routines.fetchChecklist(today);
      final weeklyProgress = await _calculateWeeklyProgress(today);
      final pendingCount = await _database.countPending();
      final conflictCount = await _database.countConflicts();
      final lastSyncAt = await _database.fetchLastSyncAt();
      final isSyncing = _ref.read(syncControllerProvider).isLoading;

      state = AsyncValue.data(
        DashboardViewModel(
          today: today,
          checklist: checklist,
          weeklyProgress: weeklyProgress,
          pendingCount: pendingCount,
          conflictCount: conflictCount,
          lastSyncAt: lastSyncAt,
          isSyncing: isSyncing,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<double> _calculateWeeklyProgress(DateTime now) async {
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final routines = await _routines.fetchRoutines();
    final completions = await _routines.fetchCompletionsForRange(
      start: weekStart,
      end: weekEnd,
    );

    // Build an expected set of routine-day pairs, then intersect with completions.
    final expectedKeys = <String>{};
    for (final routine in routines) {
      if (!routine.isActive) {
        continue;
      }
      for (var offset = 0; offset < 7; offset++) {
        final day = weekStart.add(Duration(days: offset));
        if (routine.activeDays.isEmpty ||
            routine.activeDays.contains(day.weekday)) {
          expectedKeys.add('${routine.id}-${_formatDayKey(day)}');
        }
      }
    }

    final completedKeys = <String>{};
    for (final completion in completions) {
      if (completion.isDeleted) {
        continue;
      }
      completedKeys
          .add('${completion.routineId}-${_formatDayKey(completion.date)}');
    }

    if (expectedKeys.isEmpty) {
      return 0;
    }

    final completed = completedKeys.intersection(expectedKeys).length;
    return completed / expectedKeys.length;
  }

  String _formatDayKey(DateTime day) {
    return "${day.year.toString().padLeft(4, '0')}-"
        "${day.month.toString().padLeft(2, '0')}-"
        "${day.day.toString().padLeft(2, '0')}";
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<DashboardViewModel>>(
        (ref) {
  return DashboardController(
    ref.read(routineRepositoryProvider),
    ref.read(appDatabaseProvider),
    ref,
  );
});
