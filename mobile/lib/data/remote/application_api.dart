// Application API client for pushing and pulling pipeline data during sync.
// This exists to keep network concerns separate from repositories.
// It fits in the app by supporting offline-first synchronization.
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'dto/application_dto.dart';

class ApplicationApi {
  ApplicationApi(this._apiClient);

  final ApiClient _apiClient;

  Future<ApplicationDto> upsert(ApplicationDto dto) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/applications/${dto.id}',
        data: dto.toJson(),
      );
      return ApplicationDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(String id, String clientUpdatedAt) async {
    try {
      await _apiClient.dio.delete(
        '/api/applications/$id',
        data: {'clientUpdatedAt': clientUpdatedAt},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ApplicationDto>> fetchUpdatedSince(DateTime? since) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/applications',
        queryParameters:
            since == null ? null : {'updatedSince': since.toUtc().toIso8601String()},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((entry) => ApplicationDto.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
