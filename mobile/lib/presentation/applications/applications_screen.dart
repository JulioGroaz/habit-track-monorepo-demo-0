// Applications screen with filters and timeline-style cards for job tracking.
// This exists to manage application pipelines with clear status visibility.
// It fits in the app by providing the fourth main tab.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/applications/application.dart';
import 'applications_controller.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applicationsControllerProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Applications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            FilledButton.icon(
              onPressed: () => _openApplicationForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Could not load applications. Pull to refresh.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          data: (viewState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusFilters(
                selected: viewState.statusFilter,
                onSelected: (status) => ref
                    .read(applicationsControllerProvider.notifier)
                    .setStatusFilter(status),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SourceFilters(
                selected: viewState.sourceFilter,
                onSelected: (source) => ref
                    .read(applicationsControllerProvider.notifier)
                    .setSourceFilter(source),
              ),
              const SizedBox(height: AppSpacing.md),
              if (viewState.applications.isEmpty)
                Text(
                  'No applications yet. Add your first entry.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              for (final application in viewState.applications)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ApplicationCard(
                    application: application,
                    onEdit: () => _openApplicationForm(
                      context,
                      ref,
                      application: application,
                    ),
                    onDelete: () => ref
                        .read(applicationsControllerProvider.notifier)
                        .deleteApplication(application.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Future<void> _openApplicationForm(
    BuildContext context,
    WidgetRef ref, {
    Application? application,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
      ),
      builder: (context) {
        return _ApplicationFormSheet(
          application: application,
          onSave: (draft) async {
            if (application == null) {
              await ref
                  .read(applicationsControllerProvider.notifier)
                  .createApplication(
                    company: draft.company,
                    role: draft.role,
                    source: draft.source,
                    status: draft.status,
                    lastUpdatedNote: draft.lastUpdatedNote,
                  );
            } else {
              await ref
                  .read(applicationsControllerProvider.notifier)
                  .updateApplication(
                    application.copyWith(
                      company: draft.company,
                      role: draft.role,
                      source: draft.source,
                      status: draft.status,
                      lastUpdatedNote: draft.lastUpdatedNote,
                    ),
                  );
            }
          },
        );
      },
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.onSelected});

  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelected;

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
        for (final status in ApplicationStatus.values)
          ChoiceChip(
            label: Text(status.label),
            selected: selected == status,
            onSelected: (_) => onSelected(status),
          ),
      ],
    );
  }
}

class _SourceFilters extends StatelessWidget {
  const _SourceFilters({required this.selected, required this.onSelected});

  final ApplicationSource? selected;
  final ValueChanged<ApplicationSource?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        FilterChip(
          label: const Text('All sources'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final source in ApplicationSource.values)
          FilterChip(
            label: Text(source.label),
            selected: selected == source,
            onSelected: (_) => onSelected(source),
          ),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onEdit,
    required this.onDelete,
  });

  final Application application;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status, Theme.of(context).colorScheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimelineIndicator(color: statusColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.company,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    application.role,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      _StatusChip(
                        label: application.status.label,
                        color: statusColor,
                      ),
                      _StatusChip(
                        label: application.source.label,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                  if (application.lastUpdatedNote != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      application.lastUpdatedNote!,
                      style: Theme.of(context).textTheme.bodyMedium,
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
          ],
        ),
      ),
    );
  }

  Color _statusColor(ApplicationStatus status, ColorScheme scheme) {
    switch (status) {
      case ApplicationStatus.applied:
        return scheme.primary;
      case ApplicationStatus.interview:
        return scheme.tertiary;
      case ApplicationStatus.offer:
        return scheme.secondary;
      case ApplicationStatus.rejected:
        return scheme.error;
    }
  }
}

class _TimelineIndicator extends StatelessWidget {
  const _TimelineIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 60,
          color: color.withOpacity(0.3),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _ApplicationFormDraft {
  _ApplicationFormDraft({
    required this.company,
    required this.role,
    required this.source,
    required this.status,
    required this.lastUpdatedNote,
  });

  final String company;
  final String role;
  final ApplicationSource source;
  final ApplicationStatus status;
  final String? lastUpdatedNote;
}

class _ApplicationFormSheet extends StatefulWidget {
  const _ApplicationFormSheet({
    required this.onSave,
    this.application,
  });

  final Application? application;
  final Future<void> Function(_ApplicationFormDraft draft) onSave;

  @override
  State<_ApplicationFormSheet> createState() => _ApplicationFormSheetState();
}

class _ApplicationFormSheetState extends State<_ApplicationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _roleController;
  late final TextEditingController _noteController;
  ApplicationSource _source = ApplicationSource.jobBoard;
  ApplicationStatus _status = ApplicationStatus.applied;

  @override
  void initState() {
    super.initState();
    _companyController =
        TextEditingController(text: widget.application?.company ?? '');
    _roleController = TextEditingController(text: widget.application?.role ?? '');
    _noteController =
        TextEditingController(text: widget.application?.lastUpdatedNote ?? '');
    _source = widget.application?.source ?? ApplicationSource.jobBoard;
    _status = widget.application?.status ?? ApplicationStatus.applied;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    await widget.onSave(
      _ApplicationFormDraft(
        company: _companyController.text.trim(),
        role: _roleController.text.trim(),
        source: _source,
        status: _status,
        lastUpdatedNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
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
              widget.application == null
                  ? 'Add application'
                  : 'Edit application',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter company' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Role'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter role' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<ApplicationStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ApplicationStatus.values
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
            DropdownButtonFormField<ApplicationSource>(
              value: _source,
              decoration: const InputDecoration(labelText: 'Source'),
              items: ApplicationSource.values
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(source.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _source = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Latest note',
                hintText: 'Interview, follow-up, or insight',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                widget.application == null ? 'Add application' : 'Save changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
