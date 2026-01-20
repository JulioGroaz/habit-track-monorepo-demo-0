import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/note.dart';

/// Notes API wrapper for CRUD operations.
class NotesRepository {
  NotesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Note>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/notes');
      final data = response.data as List<dynamic>;
      return data
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Note> create(String title, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/notes',
        data: {'title': title, 'content': content},
      );
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Note> update(int id, String title, String content) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/notes/$id',
        data: {'title': title, 'content': content},
      );
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _apiClient.dio.delete('/api/notes/$id');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
