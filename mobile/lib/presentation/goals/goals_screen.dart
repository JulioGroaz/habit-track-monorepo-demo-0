// Goals screen with filters and CRUD flows for focus milestones.
// This exists to let users track outcomes alongside routines.
// It fits in the app by providing one of the four main tabs.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/goals/goal.dart';
import 'goals_controller.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalsControllerProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goals',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            FilledButton.icon(
              onPressed: () => _openGoalForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New goal'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Could not load goals. Pull to refresh.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          data: (viewState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalFilters(
                selected: viewState.filter,
                onSelected: (status) =>
                    ref.read(goalsControllerProvider.notifier).setFilter(status),
              ),
              const SizedBox(height: AppSpacing.md),
              if (viewState.goals.isEmpty)
                Text(
                  'No goals yet. Create one to start.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              for (final goal in viewState.goals)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _GoalCard(
                    goal: goal,
                    onEdit: () => _openGoalForm(context, ref, goal: goal),
                    onDelete: () => ref
                        .read(goalsControllerProvider.notifier)
                        .deleteGoal(goal.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Future<void> _openGoalForm(
    BuildContext context,
    WidgetRef ref, {
    Goal? goal,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
      ),
      builder: (context) {
        return _GoalFormSheet(
          goal: goal,
          onSave: (draft) async {
            if (goal == null) {
              await ref.read(goalsControllerProvider.notifier).createGoal(
                    title: draft.title,
                    description: draft.description,
                    status: draft.status,
                    targetDate: draft.targetDate,
                  );
            } else {
              await ref.read(goalsControllerProvider.notifier).updateGoal(
                    goal.copyWith(
                      title: draft.title,
                      description: draft.description,
                      status: draft.status,
                      targetDate: draft.targetDate,
                    ),
                  );
            }
          },
        );
      },
    );
  }
}

class _GoalFilters extends StatelessWidget {
  const _GoalFilters({required this.selected, required this.onSelected});

  final GoalStatus? selected;
  final ValueChanged<GoalStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final status in GoalStatus.values)
          ChoiceChip(
            label: Text(status.label),
            selected: selected == status,
            onSelected: (_) => onSelected(status),
          ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(goal.status, scheme);

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
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    goal.status.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: statusColor,
                        ),
                  ),
                ),
              ],
            ),
            if (goal.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                goal.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (goal.targetDate != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Target: ${DateFormat('MMM d, yyyy').format(goal.targetDate!.toLocal())}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
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

  Color _statusColor(GoalStatus status, ColorScheme scheme) {
    switch (status) {
      case GoalStatus.active:
        return scheme.primary;
      case GoalStatus.paused:
        return scheme.tertiary;
      case GoalStatus.completed:
        return scheme.secondary;
    }
  }
}

class _GoalFormDraft {
  _GoalFormDraft({
    required this.title,
    required this.description,
    required this.status,
    required this.targetDate,
  });

  final String title;
  final String? description;
  final GoalStatus status;
  final DateTime? targetDate;
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({
    required this.onSave,
    this.goal,
  });

  final Goal? goal;
  final Future<void> Function(_GoalFormDraft draft) onSave;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  GoalStatus _status = GoalStatus.active;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.goal?.description ?? '');
    _status = widget.goal?.status ?? GoalStatus.active;
    _targetDate = widget.goal?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() => _targetDate = selected);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    await widget.onSave(
      _GoalFormDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: _status,
        targetDate: _targetDate,
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _targetDate == null
        ? 'Pick date'
        : DateFormat('MMM d, yyyy').format(_targetDate!.toLocal());

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
              widget.goal == null ? 'Create goal' : 'Edit goal',
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
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<GoalStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: GoalStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.date_range),
              label: Text(dateLabel),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(widget.goal == null ? 'Create goal' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
