import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/notes/presentation/notes_screen.dart';

/// Central router with auth-aware redirects.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final authStream = ref.watch(authControllerProvider.notifier).stream;

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      // Route guard: force unauthenticated users to login, and keep auth pages away when logged in.
      final loggedIn = authState.valueOrNull != null;
      final path = state.uri.path;
      final inAuthFlow = path == '/login' || path == '/register';

      if (!loggedIn && !inAuthFlow) {
        return '/login';
      }

      if (loggedIn && inAuthFlow) {
        return '/notes';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesScreen(),
      ),
    ],
  );
});

/// Bridges a stream to GoRouter refresh notifications.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
