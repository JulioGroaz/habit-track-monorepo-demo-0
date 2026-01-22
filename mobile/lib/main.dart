// App entry point that bootstraps config, providers, and the root widget tree.
// This exists so async initialization happens before any widgets render.
// It fits in the app by creating the ProviderScope and starting FocusFlow.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: FocusFlowApp()));
}
