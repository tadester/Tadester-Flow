import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/app_router.dart';
import '../../../../../shared/widgets/job_status_badge.dart';
import '../../../../jobs/presentation/widgets/worker_job_action_sheet.dart';
import '../../../domain/models/workspace_models.dart';
import '../../providers/workspace_providers.dart';
import '../../widgets/worker_shell.dart';

class WorkerJobsScreen extends ConsumerStatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  ConsumerState<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends ConsumerState<WorkerJobsScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WorkspaceSummary> workspaceAsync = ref.watch(
      workspaceProvider,
    );
    final AsyncValue<List<WorkspaceJobRecord>> jobsAsync = ref.watch(
      workspaceJobsProvider,
    );

    return workspaceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Jobs')),
        body: Center(
          child: Text(
            'Unable to load workspace.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (WorkspaceSummary workspace) => WorkerShell(
        workspace: workspace,
        currentTab: WorkerTab.jobs,
        pageTitle: 'Assigned jobs',
        onRefresh: () => invalidateWorkspaceData(ref),
        body: jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Unable to load jobs.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(workspaceJobsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (List<WorkspaceJobRecord> jobs) {
            if (jobs.isEmpty) {
              return _EmptyJobsState(
                onOptimizeRoute: () => _optimizeRoute(context),
              );
            }

            final int inProgressCount = jobs
                .where((WorkspaceJobRecord job) => job.status == 'in_progress')
                .length;
            final int scheduledCount = jobs
                .where((WorkspaceJobRecord job) => job.status == 'scheduled')
                .length;

            return ListView(
              children: <Widget>[
                _JobsCommandCard(
                  totalJobs: jobs.length,
                  inProgressJobs: inProgressCount,
                  scheduledJobs: scheduledCount,
                  isBusy: _isSubmitting,
                  onOptimizeRoute: () => _optimizeRoute(context),
                ),
                const SizedBox(height: 16),
                ...jobs.map(
                  (WorkspaceJobRecord job) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _WorkerJobCard(
                      job: job,
                      isBusy: _isSubmitting,
                      onOpen: () => context.pushNamed(
                        AppRoute.jobDetail.nameValue,
                        pathParameters: <String, String>{'id': job.id},
                      ),
                      onStart: job.status == 'scheduled'
                          ? () => _runQuickAction(
                              jobId: job.id,
                              action: 'start',
                              successMessage: '${job.title} is now in progress.',
                            )
                          : null,
                      onComplete: job.status == 'in_progress'
                          ? () => _completeJob(job)
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _runQuickAction({
    required String jobId,
    required String action,
    required String successMessage,
    String? notes,
    String? reason,
  }) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .runWorkerJobAction(
            jobId: jobId,
            action: action,
            notes: notes,
            reason: reason,
          );
      invalidateWorkspaceData(ref);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update job. $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _completeJob(WorkspaceJobRecord job) async {
    final WorkerJobActionRequest? request = await showWorkerJobActionSheet(
      context,
      jobTitle: job.title,
    );
    if (request == null) {
      return;
    }

    await _runQuickAction(
      jobId: job.id,
      action: request.action,
      notes: request.notes,
      reason: request.reason,
      successMessage: request.action == 'complete'
          ? '${job.title} marked complete.'
          : '${job.title} marked unable to complete.',
    );
  }

  void _optimizeRoute(BuildContext context) {
    ref
        .read(workerRouteDisplayModeProvider.notifier)
        .setMode(RouteDisplayMode.optimized);
    context.goNamed(AppRoute.workerRoute.nameValue, extra: WorkerTab.jobs.index);
  }
}

class _JobsCommandCard extends StatelessWidget {
  const _JobsCommandCard({
    required this.totalJobs,
    required this.inProgressJobs,
    required this.scheduledJobs,
    required this.isBusy,
    required this.onOptimizeRoute,
  });

  final int totalJobs;
  final int inProgressJobs;
  final int scheduledJobs;
  final bool isBusy;
  final VoidCallback onOptimizeRoute;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF0E8), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFFFD7CB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Today\'s field plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a stop when you arrive, then use the optimized route flow to keep the rest of your day moving cleanly.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricPill(label: 'Assigned', value: '$totalJobs'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(label: 'In progress', value: '$inProgressJobs'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(label: 'Up next', value: '$scheduledJobs'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onOptimizeRoute,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Autofind optimal route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFE53935),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerJobCard extends StatelessWidget {
  const _WorkerJobCard({
    required this.job,
    required this.onOpen,
    required this.isBusy,
    this.onStart,
    this.onComplete,
  });

  final WorkspaceJobRecord job;
  final VoidCallback onOpen;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          job.locationName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  JobStatusBadge(status: job.status),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _InfoChip(
                    icon: Icons.schedule,
                    label: _formatRange(job.scheduledStartAt, job.scheduledEndAt),
                  ),
                  _InfoChip(
                    icon: Icons.flag_outlined,
                    label: job.priority.toUpperCase(),
                  ),
                ],
              ),
              if (job.description != null && job.description!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  job.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpen,
                      child: const Text('View details'),
                    ),
                  ),
                  if (onStart != null || onComplete != null) ...<Widget>[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isBusy ? null : (onStart ?? onComplete),
                        child: Text(onStart != null ? 'Start job' : 'Done job'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFE53935)),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _EmptyJobsState extends StatelessWidget {
  const _EmptyJobsState({required this.onOptimizeRoute});

  final VoidCallback onOptimizeRoute;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.assignment_turned_in_outlined, size: 52),
              const SizedBox(height: 16),
              Text(
                'No assigned jobs right now',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'When dispatch assigns work, it will show up here and feed directly into your route plan.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOptimizeRoute,
                icon: const Icon(Icons.alt_route),
                label: const Text('Open routes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRange(DateTime start, DateTime end) {
  final String month = start.month.toString().padLeft(2, '0');
  final String day = start.day.toString().padLeft(2, '0');
  final String startHour = start.hour.toString().padLeft(2, '0');
  final String startMinute = start.minute.toString().padLeft(2, '0');
  final String endHour = end.hour.toString().padLeft(2, '0');
  final String endMinute = end.minute.toString().padLeft(2, '0');
  return '$month/$day · $startHour:$startMinute-$endHour:$endMinute';
}
