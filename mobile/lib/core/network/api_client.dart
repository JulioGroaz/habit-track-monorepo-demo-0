// Configures the Dio client with auth, retry, and session handling hooks.
// This exists so all network calls share the same headers and policies.
// It fits in the app by powering API access for auth and sync flows.
import 'dart:math';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  ApiClient(
    this._storage, {
    UnauthorizedHandler? onUnauthorized,
  }) : _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Env.apiTimeout,
        receiveTimeout: Env.apiTimeout,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      _RetryInterceptor(_dio),
    );
  }

  final TokenStorage _storage;
  final UnauthorizedHandler? _onUnauthorized;
  late final Dio _dio;

  Dio get dio => _dio;
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;
  final _jitter = Random();

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry = _shouldRetry(err);
    final retries = (err.requestOptions.extra['retries'] ?? 0) as int;

    if (!shouldRetry || retries >= maxRetries) {
      return handler.next(err);
    }

    err.requestOptions.extra['retries'] = retries + 1;
    final delay =
        Duration(milliseconds: baseDelay.inMilliseconds * (retries + 1));
    await Future.delayed(delay + Duration(milliseconds: _jitter.nextInt(120)));

    try {
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (nextError) {
      return handler.next(nextError);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final status = err.response?.statusCode ?? 0;
    return status == 408 || status == 429 || (status >= 500 && status <= 504);
  }
}
