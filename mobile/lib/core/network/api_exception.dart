import 'package:dio/dio.dart';

/// Normalized API error with optional status code.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  /// Builds a domain-friendly exception from Dio failures.
  static ApiException fromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final detail = data['detail'] ?? data['title'];
        if (detail is String && detail.isNotEmpty) {
          return ApiException(detail, statusCode: response.statusCode);
        }
      }
      return ApiException('Request failed', statusCode: response.statusCode);
    }

    return ApiException(error.message ?? 'Network error');
  }
}
