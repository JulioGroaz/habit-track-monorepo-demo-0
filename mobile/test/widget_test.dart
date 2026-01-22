// Basic widget test for FocusFlowApp to ensure the app boots with routing.
// This exists to catch regressions in the root MaterialApp configuration.
// It fits in the app by exercising the app shell with a test router.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/app.dart';
import 'package:mobile/presentation/routing/app_router.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('FocusFlowApp renders routed content', (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Smoke test')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
        ],
        child: const FocusFlowApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smoke test'), findsOneWidget);
  });
}
