// Goal API client for pushing and pulling goal data during sync.
// This exists to keep network concerns separate from repositories.
// It fits in the app by supporting offline-first synchronization.
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'dto/goal_dto.dart';

class GoalApi {
  GoalApi(this._apiClient);

  final ApiClient _apiClient;

  Future<GoalDto> upsert(GoalDto dto) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/goals/${dto.id}',
        data: dto.toJson(),
      );
      return GoalDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(String id, String clientUpdatedAt) async {
    try {
      await _apiClient.dio.delete(
        '/api/goals/$id',
        data: {'clientUpdatedAt': clientUpdatedAt},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<GoalDto>> fetchUpdatedSince(DateTime? since) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/goals',
        queryParameters:
            since == null ? null : {'updatedSince': since.toUtc().toIso8601String()},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((entry) => GoalDto.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
