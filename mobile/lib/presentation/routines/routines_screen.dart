// Routines screen for scheduling, toggling, and daily checklist management.
// This exists to let users define the habits that drive their focus.
// It fits in the app by providing the third main tab experience.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/routines/routine.dart';
import '../../domain/routines/routine_checklist_item.dart';
import 'routines_controller.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routinesControllerProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Routines',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            FilledButton.icon(
              onPressed: () => _openRoutineForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New routine'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Could not load routines. Pull to refresh.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          data: (viewState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeekdaySelector(
                selected: viewState.selectedDay,
                onSelected: (day) => ref
                    .read(routinesControllerProvider.notifier)
                    .setSelectedDay(day),
              ),
              const SizedBox(height: AppSpacing.md),
              _ChecklistCard(
                checklist: viewState.checklist,
                onToggle: (item, isChecked) => ref
                    .read(routinesControllerProvider.notifier)
                    .toggleCompletion(
                      routineId: item.routine.id,
                      isCompleted: isChecked,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'All routines',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (viewState.routines.isEmpty)
                Text(
                  'No routines yet. Add one to build momentum.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              for (final routine in viewState.routines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _RoutineCard(
                    routine: routine,
                    onToggleActive: (isActive) => ref
                        .read(routinesControllerProvider.notifier)
                        .toggleRoutineActive(routine, isActive),
                    onEdit: () =>
                        _openRoutineForm(context, ref, routine: routine),
                    onDelete: () => ref
                        .read(routinesControllerProvider.notifier)
                        .deleteRoutine(routine.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Future<void> _openRoutineForm(
    BuildContext context,
    WidgetRef ref, {
    Routine? routine,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
      ),
      builder: (context) {
        return _RoutineFormSheet(
          routine: routine,
          onSave: (draft) async {
            if (routine == null) {
              await ref.read(routinesControllerProvider.notifier).createRoutine(
                    title: draft.title,
                    notes: draft.notes,
                    activeDays: draft.activeDays,
                    isActive: draft.isActive,
                  );
            } else {
              await ref.read(routinesControllerProvider.notifier).updateRoutine(
                    routine.copyWith(
                      title: draft.title,
                      notes: draft.notes,
                      activeDays: draft.activeDays,
                      isActive: draft.isActive,
                    ),
                  );
            }
          },
        );
      },
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selected,
    required this.onSelected,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final anchor = DateTime(selected.year, selected.month, selected.day);
    final startOfWeek =
        anchor.subtract(Duration(days: anchor.weekday - 1));

    return Wrap(
      spacing: AppSpacing.sm,
      children: List.generate(7, (index) {
        final day = startOfWeek.add(Duration(days: index));
        final isSelected = day.day == selected.day &&
            day.month == selected.month &&
            day.year == selected.year;
        return ChoiceChip(
          label: Text(DateFormat('EEE').format(day)),
          selected: isSelected,
          onSelected: (_) => onSelected(day),
        );
      }),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.checklist,
    required this.onToggle,
  });

  final List<RoutineChecklistItem> checklist;
  final Future<void> Function(RoutineChecklistItem item, bool isChecked) onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily checklist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (checklist.isEmpty)
              Text(
                'No routines scheduled for this day.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            for (final item in checklist)
              CheckboxListTile(
                value: item.isCompleted,
                onChanged: (value) {
                  if (value == null) return;
                  onToggle(item, value);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(item.routine.title),
                subtitle: item.routine.notes == null
                    ? null
                    : Text(item.routine.notes!),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final Routine routine;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    routine.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: routine.isActive,
                  onChanged: onToggleActive,
                ),
              ],
            ),
            if (routine.notes != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(routine.notes!),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatDays(routine.activeDays),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDays(List<int> days) {
    if (days.isEmpty) {
      return 'Every day';
    }
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days
        .where((day) => day >= 1 && day <= 7)
        .map((day) => labels[day - 1])
        .join(', ');
  }
}

class _RoutineFormDraft {
  _RoutineFormDraft({
    required this.title,
    required this.notes,
    required this.activeDays,
    required this.isActive,
  });

  final String title;
  final String? notes;
  final List<int> activeDays;
  final bool isActive;
}

class _RoutineFormSheet extends StatefulWidget {
  const _RoutineFormSheet({
    required this.onSave,
    this.routine,
  });

  final Routine? routine;
  final Future<void> Function(_RoutineFormDraft draft) onSave;

  @override
  State<_RoutineFormSheet> createState() => _RoutineFormSheetState();
}

class _RoutineFormSheetState extends State<_RoutineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late List<int> _activeDays;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routine?.title ?? '');
    _notesController = TextEditingController(text: widget.routine?.notes ?? '');
    _activeDays = List<int>.from(widget.routine?.activeDays ?? [1, 2, 3, 4, 5]);
    _isActive = widget.routine?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    await widget.onSave(
      _RoutineFormDraft(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        activeDays: _activeDays,
        isActive: _isActive,
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.routine == null ? 'Create routine' : 'Edit routine',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Active days',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            _WeekdayPicker(
              selectedDays: _activeDays,
              onChanged: (days) => setState(() => _activeDays = days),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(widget.routine == null ? 'Create routine' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selectedDays,
    required this.onChanged,
  });

  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: AppSpacing.sm,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = selectedDays.contains(day);
        return FilterChip(
          label: Text(labels[index]),
          selected: isSelected,
          onSelected: (selected) {
            final next = List<int>.from(selectedDays);
            if (selected) {
              next.add(day);
            } else {
              next.remove(day);
            }
            next.sort();
            onChanged(next);
          },
        );
      }),
    );
  }
}
