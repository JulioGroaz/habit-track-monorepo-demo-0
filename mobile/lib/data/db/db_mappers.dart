// Shared mapping helpers for converting between Dart types and SQLite storage.
// This exists to keep serialization consistent across repositories.
// It fits in the app by supporting Drift-backed local persistence.
import 'dart:convert';

import 'package:intl/intl.dart';

final _dateFormatter = DateFormat('yyyy-MM-dd');

String formatDateTime(DateTime value) => value.toUtc().toIso8601String();

DateTime parseDateTime(Object? value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.parse(value.toString()).toUtc();
}

String formatDateOnly(DateTime value) =>
    _dateFormatter.format(DateTime(value.year, value.month, value.day));

DateTime parseDateOnly(Object? value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.parse(value.toString());
}

int boolToInt(bool value) => value ? 1 : 0;

bool intToBool(Object? value) => (value as int? ?? 0) == 1;

String encodeJson(Object value) => jsonEncode(value);

List<int> decodeIntList(Object? value) {
  if (value == null) {
    return const [];
  }
  final decoded = jsonDecode(value.toString());
  if (decoded is List) {
    return decoded.map((entry) => entry as int).toList();
  }
  return const [];
}
