// Wires up core dependencies so features can remain constructor-injected.
// This exists to keep DI centralized and test-friendly.
// It fits in the app by providing repositories, APIs, and shared services.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/db/app_database.dart';
import '../../data/remote/application_api.dart';
import '../../data/remote/goal_api.dart';
import '../../data/remote/routine_api.dart';
import '../../data/repositories/application_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../data/repositories/routine_repository_impl.dart';
import '../../data/session/session_manager.dart';
import '../../data/sync/sync_service.dart';
import '../../domain/applications/application_repository.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/goals/goal_repository.dart';
import '../../domain/routines/routine_repository.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.read(secureStorageProvider)),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.lazy();
  ref.onDispose(() {
    database.close();
  });
  return database;
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    ref.read(tokenStorageProvider),
    ref.read(appDatabaseProvider),
  );
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.read(tokenStorageProvider),
    onUnauthorized: ref.read(sessionManagerProvider).handleUnauthorized,
  );
});

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final goalApiProvider = Provider<GoalApi>(
  (ref) => GoalApi(ref.read(apiClientProvider)),
);

final routineApiProvider = Provider<RoutineApi>(
  (ref) => RoutineApi(ref.read(apiClientProvider)),
);

final applicationApiProvider = Provider<ApplicationApi>(
  (ref) => ApplicationApi(ref.read(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.read(apiClientProvider),
    ref.read(tokenStorageProvider),
  ),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepositoryImpl(ref.read(appDatabaseProvider)),
);

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepositoryImpl(ref.read(appDatabaseProvider)),
);

final applicationRepositoryProvider = Provider<ApplicationRepository>(
  (ref) => ApplicationRepositoryImpl(ref.read(appDatabaseProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    database: ref.read(appDatabaseProvider),
    goalApi: ref.read(goalApiProvider),
    routineApi: ref.read(routineApiProvider),
    applicationApi: ref.read(applicationApiProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  ),
);
