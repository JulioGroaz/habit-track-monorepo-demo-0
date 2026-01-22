// Implements auth repository with Dio calls and secure token persistence.
// This exists to isolate API details from the domain layer.
// It fits in the app by powering login, register, and profile fetch flows.
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      await _tokenStorage.writeToken(token);
      return fetchProfile();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      await _tokenStorage.writeToken(token);
      return fetchProfile();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AuthUser> fetchProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/me');
      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  @override
  Future<String?> readToken() => _tokenStorage.readToken();
}
