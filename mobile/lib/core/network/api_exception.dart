// Normalizes network exceptions so callers can handle API errors consistently.
// This exists to expose status codes and payloads to sync and UI layers.
// It fits in the app by translating Dio errors into actionable failures.
import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.payload,
  });

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? payload;

  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;

  static ApiException fromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final detail = data['detail'] ?? data['title'] ?? data['message'];
        if (detail is String && detail.isNotEmpty) {
          return ApiException(
            detail,
            statusCode: response.statusCode,
            payload: data,
          );
        }
      }
      return ApiException(
        'Request failed',
        statusCode: response.statusCode,
        payload: data is Map<String, dynamic> ? data : null,
      );
    }

    return ApiException(error.message ?? 'Network error');
  }
}
