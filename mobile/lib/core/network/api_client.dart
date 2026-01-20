import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';

/// Centralized Dio client that injects the auth token when available.
class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Env.apiTimeout,
        receiveTimeout: Env.apiTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            // Attach JWT to every request to protected endpoints.
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _storage;
  late final Dio _dio;

  Dio get dio => _dio;
}
