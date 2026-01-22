// Routine API client for syncing routines and completion records.
// This exists to keep network concerns separate from repositories.
// It fits in the app by supporting offline-first synchronization.
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'dto/routine_completion_dto.dart';
import 'dto/routine_dto.dart';

class RoutineApi {
  RoutineApi(this._apiClient);

  final ApiClient _apiClient;

  Future<RoutineDto> upsertRoutine(RoutineDto dto) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/routines/${dto.id}',
        data: dto.toJson(),
      );
      return RoutineDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteRoutine(String id, String clientUpdatedAt) async {
    try {
      await _apiClient.dio.delete(
        '/api/routines/$id',
        data: {'clientUpdatedAt': clientUpdatedAt},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<RoutineDto>> fetchRoutinesUpdatedSince(DateTime? since) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/routines',
        queryParameters:
            since == null ? null : {'updatedSince': since.toUtc().toIso8601String()},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((entry) => RoutineDto.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<RoutineCompletionDto> upsertCompletion(RoutineCompletionDto dto) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/routine-completions/${dto.id}',
        data: dto.toJson(),
      );
      return RoutineCompletionDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteCompletion(String id, String clientUpdatedAt) async {
    try {
      await _apiClient.dio.delete(
        '/api/routine-completions/$id',
        data: {'clientUpdatedAt': clientUpdatedAt},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<RoutineCompletionDto>> fetchCompletionsUpdatedSince(
    DateTime? since,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/routine-completions',
        queryParameters:
            since == null ? null : {'updatedSince': since.toUtc().toIso8601String()},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((entry) => RoutineCompletionDto.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
