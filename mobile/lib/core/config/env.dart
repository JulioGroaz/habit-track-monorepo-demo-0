import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment accessor with sane defaults for local development.
class Env {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  static Duration get apiTimeout {
    // Keep a conservative default to avoid hanging requests.
    final raw = dotenv.env['API_TIMEOUT_MS'];
    final value = int.tryParse(raw ?? '') ?? 15000;
    return Duration(milliseconds: value);
  }
}
