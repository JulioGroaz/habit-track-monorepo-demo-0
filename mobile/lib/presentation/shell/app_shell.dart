// Shell scaffold that hosts bottom navigation and the main feature tabs.
// This exists to keep navigation chrome consistent across primary screens.
// It fits in the app by wrapping Dashboard, Goals, Routines, Applications.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../sync/sync_controller.dart';
import '../widgets/app_background.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _locationToIndex(String location) {
    if (location.startsWith('/goals')) {
      return 1;
    }
    if (location.startsWith('/routines')) {
      return 2;
    }
    if (location.startsWith('/applications')) {
      return 3;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/goals');
        break;
      case 2:
        context.go('/routines');
        break;
      case 3:
        context.go('/applications');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start sync listeners when the shell is alive.
    ref.watch(syncControllerProvider);

    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: AppBackground(child: child),
      bottomNavigationBar: Semantics(
        label: 'Primary navigation',
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTap(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined),
              activeIcon: Icon(Icons.flag),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_day_outlined),
              activeIcon: Icon(Icons.view_day),
              label: 'Routines',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Applications',
            ),
          ],
        ),
      ),
    );
  }
}
