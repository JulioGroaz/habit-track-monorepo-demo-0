import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

/// Auth state provider used by routing and UI.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

/// Coordinates auth flows and exposes the current user as AsyncValue.
class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final AuthRepository _repository;

  Future<void> _initialize() async {
    // Restore session from storage if a token exists.
    final token = await _repository.readToken();
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final user = await _repository.fetchMe();
      state = AsyncValue.data(user);
    } catch (_) {
      // Token is invalid or expired; clear it and reset the session.
      await _repository.logout();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.login(email, password));
  }

  Future<void> register(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.register(email, password));
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
