// Repository contract for routines to decouple UI from persistence details.
// This exists to define CRUD and checklist operations in one interface.
// It fits in the app by driving routine management and daily checklists.
import 'routine.dart';
import 'routine_checklist_item.dart';
import 'routine_completion.dart';

abstract class RoutineRepository {
  Future<List<Routine>> fetchRoutines({bool includeDeleted = false});

  Future<void> upsertRoutine(Routine routine);

  Future<void> markRoutineDeleted(String id);

  Future<List<RoutineCompletion>> fetchCompletionsForRange({
    required DateTime start,
    required DateTime end,
  });

  Future<List<RoutineCompletion>> fetchCompletionsForDay(DateTime day);

  Future<List<RoutineChecklistItem>> fetchChecklist(DateTime day);

  Future<void> toggleCompletion({
    required String routineId,
    required DateTime day,
    required bool isCompleted,
  });
}
