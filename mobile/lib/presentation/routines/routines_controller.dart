// Manages routine list, checklist day selection, and CRUD actions.
// This exists to keep routine UI reactive without mixing in persistence logic.
// It fits in the app by powering the Routines tab and daily checklist.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/routines/routine.dart';
import '../../domain/routines/routine_checklist_item.dart';
import '../../domain/routines/routine_repository.dart';
import '../../domain/sync/sync_status.dart';

class RoutinesViewState {
  RoutinesViewState({
    required this.routines,
    required this.checklist,
    required this.selectedDay,
  });

  final List<Routine> routines;
  final List<RoutineChecklistItem> checklist;
  final DateTime selectedDay;
}

class RoutinesController
    extends StateNotifier<AsyncValue<RoutinesViewState>> {
  RoutinesController(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(const AsyncValue.loading()) {
    _selectedDay = _normalizeDay(DateTime.now());
    load();
  }

  final RoutineRepository _repository;
  final Uuid _uuid;
  late DateTime _selectedDay;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final routines = await _repository.fetchRoutines();
      final checklist = await _repository.fetchChecklist(_selectedDay);
      state = AsyncValue.data(
        RoutinesViewState(
          routines: routines,
          checklist: checklist,
          selectedDay: _selectedDay,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setSelectedDay(DateTime day) async {
    _selectedDay = _normalizeDay(day);
    await load();
  }

  Future<void> createRoutine({
    required String title,
    String? notes,
    required List<int> activeDays,
    bool isActive = true,
  }) async {
    final now = DateTime.now().toUtc();
    final routine = Routine(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      activeDays: activeDays,
      isActive: isActive,
      clientUpdatedAt: now,
      serverUpdatedAt: now,
      isDeleted: false,
      syncStatus: SyncStatus.pending,
    );
    await _repository.upsertRoutine(routine);
    await load();
  }

  Future<void> updateRoutine(Routine routine) async {
    final now = DateTime.now().toUtc();
    final updated = routine.copyWith(
      clientUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    await _repository.upsertRoutine(updated);
    await load();
  }

  Future<void> toggleRoutineActive(Routine routine, bool isActive) async {
    final now = DateTime.now().toUtc();
    final updated = routine.copyWith(
      isActive: isActive,
      clientUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    await _repository.upsertRoutine(updated);
    await load();
  }

  Future<void> deleteRoutine(String id) async {
    await _repository.markRoutineDeleted(id);
    await load();
  }

  Future<void> toggleCompletion({
    required String routineId,
    required bool isCompleted,
  }) async {
    await _repository.toggleCompletion(
      routineId: routineId,
      day: _selectedDay,
      isCompleted: isCompleted,
    );
    await load();
  }

  DateTime _normalizeDay(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }
}

final routinesControllerProvider =
    StateNotifierProvider<RoutinesController, AsyncValue<RoutinesViewState>>(
        (ref) {
  return RoutinesController(ref.read(routineRepositoryProvider));
});
