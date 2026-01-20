import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

/// Notes state provider that loads and mutates the note list.
final notesControllerProvider =
    StateNotifierProvider<NotesController, AsyncValue<List<Note>>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return NotesController(repository);
});

/// Coordinates note CRUD and exposes results as AsyncValue.
class NotesController extends StateNotifier<AsyncValue<List<Note>>> {
  NotesController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final NotesRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.list);
  }

  Future<void> addNote(String title, String content) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();
    try {
      final created = await _repository.create(title, content);
      state = AsyncValue.data([...current, created]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateNote(int id, String title, String content) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.update(id, title, content);
      final next = [
        for (final note in current) if (note.id == id) updated else note
      ];
      state = AsyncValue.data(next);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteNote(int id) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = AsyncValue.data(current.where((note) => note.id != id).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
