// Riverpod controller for authentication state and session lifecycle.
// This exists to keep UI logic separate from auth/network concerns.
// It fits in the app by driving login flow, routing guards, and logout.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/session/session_manager.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_user.dart';

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._authRepository, this._sessionManager)
      : super(const AsyncValue.loading()) {
    _initialize();
  }

  final AuthRepository _authRepository;
  final SessionManager _sessionManager;
  StreamSubscription<void>? _logoutSubscription;

  Future<void> _initialize() async {
    _logoutSubscription = _sessionManager.logoutStream.listen((_) {
      state = const AsyncValue.data(null);
    });

    final token = await _authRepository.readToken();
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final user = await _authRepository.fetchProfile();
      state = AsyncValue.data(user);
    } catch (_) {
      // If the session is invalid, treat it as logged out.
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> register({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _sessionManager.logout();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    ref.read(sessionManagerProvider),
  );
});
