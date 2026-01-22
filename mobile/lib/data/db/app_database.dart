// Drift-backed SQLite wrapper that provides offline-first local persistence.
// This exists to centralize schema creation and CRUD helpers for repositories.
// It fits in the app by acting as the source of truth for syncable data.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/applications/application.dart';
import '../../domain/goals/goal.dart';
import '../../domain/routines/routine.dart';
import '../../domain/routines/routine_completion.dart';
import '../../domain/sync/conflict_record.dart';
import '../../domain/sync/sync_status.dart';
import 'db_mappers.dart';

class AppDatabase {
  AppDatabase(this._executor);

  factory AppDatabase.lazy() {
    final executor = LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, 'focusflow.sqlite'));
      return NativeDatabase(file);
    });

    return AppDatabase(executor);
  }

  final QueryExecutor _executor;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _executor.runCustom('PRAGMA foreign_keys = ON');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        targetDate TEXT,
        clientUpdatedAt TEXT NOT NULL,
        serverUpdatedAt TEXT NOT NULL,
        isDeleted INTEGER NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS routines (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        activeDays TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        clientUpdatedAt TEXT NOT NULL,
        serverUpdatedAt TEXT NOT NULL,
        isDeleted INTEGER NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS routine_completions (
        id TEXT PRIMARY KEY,
        routineId TEXT NOT NULL,
        date TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        clientUpdatedAt TEXT NOT NULL,
        serverUpdatedAt TEXT NOT NULL,
        isDeleted INTEGER NOT NULL,
        syncStatus TEXT NOT NULL,
        FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE,
        UNIQUE(routineId, date)
      )
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS applications (
        id TEXT PRIMARY KEY,
        company TEXT NOT NULL,
        role TEXT NOT NULL,
        source TEXT NOT NULL,
        status TEXT NOT NULL,
        lastUpdatedNote TEXT,
        clientUpdatedAt TEXT NOT NULL,
        serverUpdatedAt TEXT NOT NULL,
        isDeleted INTEGER NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS conflicts (
        id TEXT PRIMARY KEY,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        localSnapshot TEXT NOT NULL,
        remoteSnapshot TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS sync_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _executor.runCustom(
        'CREATE INDEX IF NOT EXISTS idx_goals_sync ON goals(syncStatus)');
    await _executor.runCustom(
        'CREATE INDEX IF NOT EXISTS idx_routines_sync ON routines(syncStatus)');
    await _executor.runCustom(
        'CREATE INDEX IF NOT EXISTS idx_completions_sync ON routine_completions(syncStatus)');
    await _executor.runCustom(
        'CREATE INDEX IF NOT EXISTS idx_applications_sync ON applications(syncStatus)');
    await _executor.runCustom(
        'CREATE INDEX IF NOT EXISTS idx_completions_date ON routine_completions(date)');

    _initialized = true;
  }

  Future<void> close() => _executor.close();

  Future<void> clearAll() async {
    await _ensureInitialized();
    await _executor.runCustom('DELETE FROM goals');
    await _executor.runCustom('DELETE FROM routines');
    await _executor.runCustom('DELETE FROM routine_completions');
    await _executor.runCustom('DELETE FROM applications');
    await _executor.runCustom('DELETE FROM conflicts');
    await _executor.runCustom('DELETE FROM sync_state');
  }

  Future<int> countConflicts() async {
    await _ensureInitialized();
    final rows = await _executor.runSelect('SELECT COUNT(*) as total FROM conflicts', []);
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<int> countPending() async {
    await _ensureInitialized();
    final pendingStatus = SyncStatus.pending.toStorageString();
    final goalRows = await _executor.runSelect(
      'SELECT COUNT(*) as total FROM goals WHERE syncStatus = ?',
      [pendingStatus],
    );
    final routineRows = await _executor.runSelect(
      'SELECT COUNT(*) as total FROM routines WHERE syncStatus = ?',
      [pendingStatus],
    );
    final completionRows = await _executor.runSelect(
      'SELECT COUNT(*) as total FROM routine_completions WHERE syncStatus = ?',
      [pendingStatus],
    );
    final applicationRows = await _executor.runSelect(
      'SELECT COUNT(*) as total FROM applications WHERE syncStatus = ?',
      [pendingStatus],
    );

    return (goalRows.first['total'] as int? ?? 0) +
        (routineRows.first['total'] as int? ?? 0) +
        (completionRows.first['total'] as int? ?? 0) +
        (applicationRows.first['total'] as int? ?? 0);
  }

  Future<DateTime?> fetchLastSyncAt() async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT value FROM sync_state WHERE key = ?',
      ['last_sync_at'],
    );
    if (rows.isEmpty) {
      return null;
    }
    return parseDateTime(rows.first['value']);
  }

  Future<void> setLastSyncAt(DateTime value) async {
    await _ensureInitialized();
    await _executor.runInsert(
      'INSERT INTO sync_state (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      ['last_sync_at', formatDateTime(value)],
    );
  }

  Future<void> insertConflict(ConflictRecord record) async {
    await _ensureInitialized();
    await _executor.runInsert(
      'INSERT INTO conflicts (id, entityType, entityId, localSnapshot, remoteSnapshot, createdAt) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [
        record.id,
        record.entityType,
        record.entityId,
        record.localSnapshot,
        record.remoteSnapshot,
        formatDateTime(record.createdAt),
      ],
    );
  }

  Future<List<ConflictRecord>> fetchConflicts() async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM conflicts ORDER BY createdAt DESC',
      [],
    );
    return rows
        .map(
          (row) => ConflictRecord(
            id: row['id'] as String,
            entityType: row['entityType'] as String,
            entityId: row['entityId'] as String,
            localSnapshot: row['localSnapshot'] as String,
            remoteSnapshot: row['remoteSnapshot'] as String,
            createdAt: parseDateTime(row['createdAt']),
          ),
        )
        .toList();
  }

  Future<void> upsertGoal(Goal goal) async {
    await _ensureInitialized();
    await _executor.runInsert(
      'INSERT INTO goals (id, title, description, status, targetDate, clientUpdatedAt, serverUpdatedAt, isDeleted, syncStatus) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET '
      'title = excluded.title, '
      'description = excluded.description, '
      'status = excluded.status, '
      'targetDate = excluded.targetDate, '
      'clientUpdatedAt = excluded.clientUpdatedAt, '
      'serverUpdatedAt = excluded.serverUpdatedAt, '
      'isDeleted = excluded.isDeleted, '
      'syncStatus = excluded.syncStatus',
      [
        goal.id,
        goal.title,
        goal.description,
        goal.status.toStorageString(),
        goal.targetDate == null ? null : formatDateTime(goal.targetDate!),
        formatDateTime(goal.clientUpdatedAt),
        formatDateTime(goal.serverUpdatedAt),
        boolToInt(goal.isDeleted),
        goal.syncStatus.toStorageString(),
      ],
    );
  }

  Future<List<Goal>> fetchGoals({
    GoalStatus? status,
    bool includeDeleted = false,
    SyncStatus? syncStatus,
  }) async {
    await _ensureInitialized();
    final clauses = <String>[];
    final args = <Object?>[];

    if (!includeDeleted) {
      clauses.add('isDeleted = 0');
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(status.toStorageString());
    }
    if (syncStatus != null) {
      clauses.add('syncStatus = ?');
      args.add(syncStatus.toStorageString());
    }

    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _executor.runSelect(
      'SELECT * FROM goals $where ORDER BY clientUpdatedAt DESC',
      args,
    );

    return rows.map(_mapGoal).toList();
  }

  Future<Goal?> fetchGoalById(String id) async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM goals WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapGoal(rows.first);
  }

  Future<void> upsertRoutine(Routine routine) async {
    await _ensureInitialized();
    await _executor.runInsert(
      'INSERT INTO routines (id, title, notes, activeDays, isActive, clientUpdatedAt, serverUpdatedAt, isDeleted, syncStatus) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET '
      'title = excluded.title, '
      'notes = excluded.notes, '
      'activeDays = excluded.activeDays, '
      'isActive = excluded.isActive, '
      'clientUpdatedAt = excluded.clientUpdatedAt, '
      'serverUpdatedAt = excluded.serverUpdatedAt, '
      'isDeleted = excluded.isDeleted, '
      'syncStatus = excluded.syncStatus',
      [
        routine.id,
        routine.title,
        routine.notes,
        encodeJson(routine.activeDays),
        boolToInt(routine.isActive),
        formatDateTime(routine.clientUpdatedAt),
        formatDateTime(routine.serverUpdatedAt),
        boolToInt(routine.isDeleted),
        routine.syncStatus.toStorageString(),
      ],
    );
  }

  Future<List<Routine>> fetchRoutines({
    bool includeDeleted = false,
    SyncStatus? syncStatus,
  }) async {
    await _ensureInitialized();
    final clauses = <String>[];
    final args = <Object?>[];

    if (!includeDeleted) {
      clauses.add('isDeleted = 0');
    }
    if (syncStatus != null) {
      clauses.add('syncStatus = ?');
      args.add(syncStatus.toStorageString());
    }

    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _executor.runSelect(
      'SELECT * FROM routines $where ORDER BY title COLLATE NOCASE ASC',
      args,
    );

    return rows.map(_mapRoutine).toList();
  }

  Future<Routine?> fetchRoutineById(String id) async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM routines WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapRoutine(rows.first);
  }

  Future<void> upsertCompletion(RoutineCompletion completion) async {
    await _ensureInitialized();
    await _executor.runInsert(
      'INSERT INTO routine_completions (id, routineId, date, completedAt, clientUpdatedAt, serverUpdatedAt, isDeleted, syncStatus) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(routineId, date) DO UPDATE SET '
      'completedAt = excluded.completedAt, '
      'clientUpdatedAt = excluded.clientUpdatedAt, '
      'serverUpdatedAt = excluded.serverUpdatedAt, '
      'isDeleted = excluded.isDeleted, '
      'syncStatus = excluded.syncStatus',
      [
        completion.id,
        completion.routineId,
        formatDateOnly(completion.date),
        formatDateTime(completion.completedAt),
        formatDateTime(completion.clientUpdatedAt),
        formatDateTime(completion.serverUpdatedAt),
        boolToInt(completion.isDeleted),
        completion.syncStatus.toStorageString(),
      ],
    );
  }

  Future<List<RoutineCompletion>> fetchCompletionsForDay(DateTime day) async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM routine_completions WHERE date = ?',
      [formatDateOnly(day)],
    );
    return rows.map(_mapCompletion).toList();
  }

  Future<List<RoutineCompletion>> fetchCompletionsForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM routine_completions WHERE date BETWEEN ? AND ?',
      [formatDateOnly(start), formatDateOnly(end)],
    );
    return rows.map(_mapCompletion).toList();
  }

  Future<List<RoutineCompletion>> fetchCompletionsBySyncStatus(
    SyncStatus status,
  ) async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM routine_completions WHERE syncStatus = ?',
      [status.toStorageString()],
    );
    return rows.map(_mapCompletion).toList();
  }

  Future<RoutineCompletion?> fetchCompletionById(String id) async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM routine_completions WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapCompletion(rows.first);
  }

  Future<void> upsertApplication(Application application) async {
    await _ensureInitialized();
    await _executor.runInsert(
      'INSERT INTO applications (id, company, role, source, status, lastUpdatedNote, clientUpdatedAt, serverUpdatedAt, isDeleted, syncStatus) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET '
      'company = excluded.company, '
      'role = excluded.role, '
      'source = excluded.source, '
      'status = excluded.status, '
      'lastUpdatedNote = excluded.lastUpdatedNote, '
      'clientUpdatedAt = excluded.clientUpdatedAt, '
      'serverUpdatedAt = excluded.serverUpdatedAt, '
      'isDeleted = excluded.isDeleted, '
      'syncStatus = excluded.syncStatus',
      [
        application.id,
        application.company,
        application.role,
        application.source.toStorageString(),
        application.status.toStorageString(),
        application.lastUpdatedNote,
        formatDateTime(application.clientUpdatedAt),
        formatDateTime(application.serverUpdatedAt),
        boolToInt(application.isDeleted),
        application.syncStatus.toStorageString(),
      ],
    );
  }

  Future<List<Application>> fetchApplications({
    ApplicationStatus? status,
    ApplicationSource? source,
    bool includeDeleted = false,
    SyncStatus? syncStatus,
  }) async {
    await _ensureInitialized();
    final clauses = <String>[];
    final args = <Object?>[];

    if (!includeDeleted) {
      clauses.add('isDeleted = 0');
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(status.toStorageString());
    }
    if (source != null) {
      clauses.add('source = ?');
      args.add(source.toStorageString());
    }
    if (syncStatus != null) {
      clauses.add('syncStatus = ?');
      args.add(syncStatus.toStorageString());
    }

    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _executor.runSelect(
      'SELECT * FROM applications $where ORDER BY clientUpdatedAt DESC',
      args,
    );

    return rows.map(_mapApplication).toList();
  }

  Future<Application?> fetchApplicationById(String id) async {
    await _ensureInitialized();
    final rows = await _executor.runSelect(
      'SELECT * FROM applications WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapApplication(rows.first);
  }

  Goal _mapGoal(Map<String, Object?> row) {
    return Goal(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      status: GoalStatusStorage.fromStorage(row['status'] as String),
      targetDate: row['targetDate'] == null
          ? null
          : parseDateTime(row['targetDate']),
      clientUpdatedAt: parseDateTime(row['clientUpdatedAt']),
      serverUpdatedAt: parseDateTime(row['serverUpdatedAt']),
      isDeleted: intToBool(row['isDeleted']),
      syncStatus: SyncStatusStorage.fromStorage(row['syncStatus'] as String),
    );
  }

  Routine _mapRoutine(Map<String, Object?> row) {
    return Routine(
      id: row['id'] as String,
      title: row['title'] as String,
      notes: row['notes'] as String?,
      activeDays: decodeIntList(row['activeDays']),
      isActive: intToBool(row['isActive']),
      clientUpdatedAt: parseDateTime(row['clientUpdatedAt']),
      serverUpdatedAt: parseDateTime(row['serverUpdatedAt']),
      isDeleted: intToBool(row['isDeleted']),
      syncStatus: SyncStatusStorage.fromStorage(row['syncStatus'] as String),
    );
  }

  RoutineCompletion _mapCompletion(Map<String, Object?> row) {
    return RoutineCompletion(
      id: row['id'] as String,
      routineId: row['routineId'] as String,
      date: parseDateOnly(row['date']),
      completedAt: parseDateTime(row['completedAt']),
      clientUpdatedAt: parseDateTime(row['clientUpdatedAt']),
      serverUpdatedAt: parseDateTime(row['serverUpdatedAt']),
      isDeleted: intToBool(row['isDeleted']),
      syncStatus: SyncStatusStorage.fromStorage(row['syncStatus'] as String),
    );
  }

  Application _mapApplication(Map<String, Object?> row) {
    return Application(
      id: row['id'] as String,
      company: row['company'] as String,
      role: row['role'] as String,
      source: ApplicationSourceStorage.fromStorage(row['source'] as String),
      status: ApplicationStatusStorage.fromStorage(row['status'] as String),
      lastUpdatedNote: row['lastUpdatedNote'] as String?,
      clientUpdatedAt: parseDateTime(row['clientUpdatedAt']),
      serverUpdatedAt: parseDateTime(row['serverUpdatedAt']),
      isDeleted: intToBool(row['isDeleted']),
      syncStatus: SyncStatusStorage.fromStorage(row['syncStatus'] as String),
    );
  }
}
