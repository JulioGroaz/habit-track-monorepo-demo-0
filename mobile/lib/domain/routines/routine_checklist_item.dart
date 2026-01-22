// Combines a routine with completion state for daily checklist rendering.
// This exists to keep checklist UI logic simple and explicit.
// It fits in the app by driving the Dashboard and Routines checklist views.
import 'routine.dart';

class RoutineChecklistItem {
  RoutineChecklistItem({
    required this.routine,
    required this.isCompleted,
  });

  final Routine routine;
  final bool isCompleted;
}
