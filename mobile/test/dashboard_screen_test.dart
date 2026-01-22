// Widget test for the dashboard to ensure main UI renders key sections.
// This exists to guard the primary screen against layout regressions.
// It fits in the app by validating the user-facing landing experience.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/domain/routines/routine.dart';
import 'package:mobile/domain/routines/routine_checklist_item.dart';
import 'package:drift/native.dart';

import 'package:mobile/core/di/providers.dart';
import 'package:mobile/data/db/app_database.dart';
import 'package:mobile/data/sync/sync_service.dart';
import 'package:mobile/domain/routines/routine_repository.dart';
import 'package:mobile/domain/routines/routine_completion.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:mobile/domain/sync/sync_report.dart';
import 'package:mobile/domain/sync/sync_status.dart';
import 'package:mobile/presentation/dashboard/dashboard_screen.dart';
import 'package:mobile/presentation/sync/sync_controller.dart';

class FakeRoutineRepository implements RoutineRepository {
  FakeRoutineRepository(this._routine);

  final Routine _routine;

  @override
  Future<List<Routine>> fetchRoutines({bool includeDeleted = false}) async =>
      [_routine];

  @override
  Future<void> upsertRoutine(Routine routine) async {}

  @override
  Future<void> markRoutineDeleted(String id) async {}

  @override
  Future<List<RoutineCompletion>> fetchCompletionsForRange({
    required DateTime start,
    required DateTime end,
  }) async =>
      [];

  @override
  Future<List<RoutineCompletion>> fetchCompletionsForDay(DateTime day) async =>
      [];

  @override
  Future<List<RoutineChecklistItem>> fetchChecklist(DateTime day) async => [
        RoutineChecklistItem(routine: _routine, isCompleted: false),
      ];

  @override
  Future<void> toggleCompletion({
    required String routineId,
    required DateTime day,
    required bool isCompleted,
  }) async {}
}

class FakeAppDatabase extends AppDatabase {
  FakeAppDatabase() : super(NativeDatabase.memory());

  @override
  Future<int> countPending() async => 2;

  @override
  Future<int> countConflicts() async => 0;

  @override
  Future<DateTime?> fetchLastSyncAt() async =>
      DateTime(2026, 1, 20, 9, 0);
}

class FakeSyncService implements SyncService {
  @override
  Future<SyncReport> syncAll() async {
    final now = DateTime(2026, 1, 20, 9, 0);
    return SyncReport(
      startedAt: now,
      finishedAt: now,
      pushed: 0,
      pulled: 0,
      conflicts: 0,
    );
  }
}

class FakeConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      const [ConnectivityResult.none];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream<List<ConnectivityResult>>.empty();
}

void main() {
  testWidgets('Dashboard renders key sections', (tester) async {
    final now = DateTime(2026, 1, 20);
    final routine = Routine(
      id: 'r1',
      title: 'Focus sprint',
      notes: '45 minutes',
      activeDays: const [1, 2, 3, 4, 5],
      isActive: true,
      clientUpdatedAt: now,
      serverUpdatedAt: now,
      isDeleted: false,
      syncStatus: SyncStatus.synced,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routineRepositoryProvider.overrideWithValue(
            FakeRoutineRepository(routine),
          ),
          appDatabaseProvider.overrideWithValue(FakeAppDatabase()),
          syncControllerProvider.overrideWith(
            (ref) => SyncController(
              FakeSyncService(),
              FakeConnectivity(),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Today routines'), findsOneWidget);
    expect(find.text('Focus sprint'), findsOneWidget);
  });
}
