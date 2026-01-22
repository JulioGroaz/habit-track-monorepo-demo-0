// Repository contract for goals to keep domain logic independent from storage.
// This exists so presentation can rely on goals without knowing where they live.
// It fits in the app by powering CRUD and filter behavior in the Goals screen.
import '../sync/sync_status.dart';
import 'goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> fetchGoals({
    GoalStatus? status,
    bool includeDeleted = false,
  });

  Future<Goal?> fetchGoalById(String id);

  Future<void> upsertGoal(Goal goal);

  Future<void> markGoalDeleted(String id);

  Future<List<Goal>> fetchGoalsBySyncStatus(SyncStatus status);
}
