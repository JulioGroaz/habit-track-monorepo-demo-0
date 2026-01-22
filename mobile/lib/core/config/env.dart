// Reads environment configuration so network setup stays centralized.
// This exists to avoid scattering API constants across the codebase.
// It fits in the app by feeding ApiClient and sync services.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  static Duration get apiTimeout {
    final raw = dotenv.env['API_TIMEOUT_MS'];
    final value = int.tryParse(raw ?? '') ?? 15000;
    return Duration(milliseconds: value);
  }
}
