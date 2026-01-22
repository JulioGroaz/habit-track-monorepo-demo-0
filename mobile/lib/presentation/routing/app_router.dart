// Defines the navigation graph and auth-aware redirects for the app.
// This exists to keep routing centralized and declarative.
// It fits in the app by gating access to the shell when unauthenticated.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../shell/app_shell.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../goals/goals_screen.dart';
import '../routines/routines_screen.dart';
import '../applications/applications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final authStream = ref.watch(authControllerProvider.notifier).stream;

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final loggedIn = authState.valueOrNull != null;
      final path = state.uri.path;
      final inAuthFlow = path == '/login' || path == '/register';

      if (!loggedIn && !inAuthFlow) {
        return '/login';
      }

      if (loggedIn && inAuthFlow) {
        return '/dashboard';
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
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/routines',
            builder: (context, state) => const RoutinesScreen(),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) => const ApplicationsScreen(),
          ),
        ],
      ),
    ],
  );
});

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
