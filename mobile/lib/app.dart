// Root application widget that wires theme, routing, and global UI behavior.
// This exists to keep MaterialApp configuration in one place for clarity.
// It fits in the app by composing the theme system and navigation tree.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/routing/app_router.dart';

class FocusFlowApp extends ConsumerWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FocusFlow',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      routerConfig: router,
    );
  }
}
