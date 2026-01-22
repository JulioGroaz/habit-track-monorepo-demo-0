// Controls sync execution and connectivity triggers for offline-first behavior.
// This exists to run sync on start, refresh, and network changes.
// It fits in the app by exposing sync status to the dashboard and shell.
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/sync/sync_report.dart';
import '../../data/sync/sync_service.dart';

class SyncController extends StateNotifier<AsyncValue<SyncReport?>> {
  SyncController(this._syncService, this._connectivity)
      : super(const AsyncValue.data(null)) {
    _initialize();
  }

  final SyncService _syncService;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  Future<void> _initialize() async {
    await syncAll();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection =
          results.any((entry) => entry != ConnectivityResult.none);
      if (hasConnection) {
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    state = const AsyncValue.loading();
    try {
      final report = await _syncService.syncAll();
      state = AsyncValue.data(report);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, AsyncValue<SyncReport?>>((ref) {
  return SyncController(
    ref.read(syncServiceProvider),
    ref.read(connectivityProvider),
  );
});
