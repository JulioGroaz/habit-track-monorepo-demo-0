// Dashboard screen showing today's routines, progress, and sync health.
// This exists to give users a quick overview of their focus flow.
// It fits in the app by being the landing tab after authentication.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/routines/routine_checklist_item.dart';
import '../auth/auth_controller.dart';
import '../sync/sync_controller.dart';
import '../widgets/staggered_fade_in.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncControllerProvider, (_, __) {
      ref.read(dashboardControllerProvider.notifier).load();
    });

    final state = ref.watch(dashboardControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(syncControllerProvider.notifier).syncAll();
        await ref.read(dashboardControllerProvider.notifier).load();
      },
      child: state.when(
        loading: () => ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: AppSpacing.xl),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (error, _) => ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Dashboard is taking a breath. Pull to refresh.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        data: (model) {
          final dateLabel = DateFormat('EEE, MMM d').format(model.today);
          final progressPercent = (model.weeklyProgress * 100).round();

          return ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 50),
                child: _Header(
                  dateLabel: dateLabel,
                  onLogout: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (model.conflictCount > 0)
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: _ConflictBanner(conflictCount: model.conflictCount),
                ),
              if (model.conflictCount > 0) const SizedBox(height: AppSpacing.sm),
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 180),
                child: _SyncCard(
                  pendingCount: model.pendingCount,
                  conflictCount: model.conflictCount,
                  lastSyncAt: model.lastSyncAt,
                  isSyncing: model.isSyncing,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 240),
                child: _QuickActions(
                  onGoals: () => context.go('/goals'),
                  onRoutines: () => context.go('/routines'),
                  onApplications: () => context.go('/applications'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 300),
                child: _ChecklistCard(
                  checklist: model.checklist,
                  onToggle: (item, isChecked) async {
                    await ref.read(routineRepositoryProvider).toggleCompletion(
                          routineId: item.routine.id,
                          day: model.today,
                          isCompleted: isChecked,
                        );
                    await ref.read(dashboardControllerProvider.notifier).load();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 360),
                child: _WeeklyProgressCard(progressPercent: progressPercent),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.dateLabel,
    required this.onLogout,
  });

  final String dateLabel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Icon(
                Icons.bolt,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ),
      ],
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.conflictCount});

  final int conflictCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.warning_amber,
                color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Conflicts detected: $conflictCount. Review before syncing.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.pendingCount,
    required this.conflictCount,
    required this.lastSyncAt,
    required this.isSyncing,
  });

  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSyncAt;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final label = lastSyncAt == null
        ? 'Never synced'
        : DateFormat('MMM d, HH:mm').format(lastSyncAt!.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                isSyncing ? Icons.sync : Icons.cloud_done,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSyncing ? 'Syncing...' : 'Sync status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$pendingCount pending, $conflictCount conflicts',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onGoals,
    required this.onRoutines,
    required this.onApplications,
  });

  final VoidCallback onGoals;
  final VoidCallback onRoutines;
  final VoidCallback onApplications;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ActionChip(
                  onPressed: onGoals,
                  label: const Text('Add goal'),
                  avatar: const Icon(Icons.flag),
                ),
                ActionChip(
                  onPressed: onRoutines,
                  label: const Text('Add routine'),
                  avatar: const Icon(Icons.view_day),
                ),
                ActionChip(
                  onPressed: onApplications,
                  label: const Text('Add application'),
                  avatar: const Icon(Icons.work),
                ),
              ],
            ),
          ],
        ),
      ),
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
              'Today routines',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (checklist.isEmpty)
              Text(
                'No routines scheduled for today.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            for (final item in checklist)
              CheckboxListTile(
                value: item.isCompleted,
                onChanged: (value) {
                  if (value == null) return;
                  onToggle(item, value);
                },
                dense: false,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
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

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.progressPercent});

  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final progressValue = progressPercent / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$progressPercent% complete',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
