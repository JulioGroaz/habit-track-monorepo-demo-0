import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_user.dart';

/// Auth API wrapper: register, login, fetch profile, and manage token.
class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthUser> register(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/register',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      await _tokenStorage.writeToken(token);
      return fetchMe();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthUser> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'] as String;
      await _tokenStorage.writeToken(token);
      return fetchMe();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthUser> fetchMe() async {
    try {
      final response = await _apiClient.dio.get('/api/me');
      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout() {
    return _tokenStorage.deleteToken();
  }

  Future<String?> readToken() {
    return _tokenStorage.readToken();
  }
}
