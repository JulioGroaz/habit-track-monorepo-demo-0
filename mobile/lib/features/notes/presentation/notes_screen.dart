import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/note.dart';
import 'notes_controller.dart';

/// Notes list screen with inline create/edit dialog.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  /// Opens a modal editor for creating or updating a note.
  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Note? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    final formKey = GlobalKey<FormState>();

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(existing == null ? 'New note' : 'Edit note'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                    minLines: 2,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Content required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true) {
        final title = titleController.text.trim();
        final content = contentController.text.trim();
        final controller = ref.read(notesControllerProvider.notifier);
        if (existing == null) {
          await controller.addNote(title, content);
        } else {
          await controller.updateNote(existing.id, title, content);
        }
      }
    } finally {
      titleController.dispose();
      contentController.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          )
        ],
      ),
      body: notesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(notesControllerProvider.notifier).load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet.'));
          }

          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Dismissible(
                key: ValueKey(note.id),
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(notesControllerProvider.notifier).deleteNote(note.id);
                },
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _openEditor(context, ref, existing: note),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
