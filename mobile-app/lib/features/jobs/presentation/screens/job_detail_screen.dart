import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/job_status_badge.dart';
import '../widgets/worker_job_action_sheet.dart';
import '../../../profile/domain/models/workspace_models.dart';
import '../../../profile/presentation/providers/workspace_providers.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WorkspaceSummary> workspaceAsync = ref.watch(
      workspaceProvider,
    );
    final AsyncValue<List<WorkspaceJobRecord>> jobsAsync = ref.watch(
      workspaceJobsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Job detail')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: workspaceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) => Center(
              child: Text(
                'Unable to load workspace.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
            data: (WorkspaceSummary workspace) => jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) => Center(
                child: Text(
                  'Unable to load job details.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
              data: (List<WorkspaceJobRecord> jobs) {
                WorkspaceJobRecord? selectedJob;
                for (final WorkspaceJobRecord job in jobs) {
                  if (job.id == widget.jobId) {
                    selectedJob = job;
                    break;
                  }
                }

                if (selectedJob == null) {
                  return const Center(child: Text('Job not found'));
                }

                return ListView(
                  children: <Widget>[
                    _JobHeroCard(job: selectedJob),
                    const SizedBox(height: 16),
                    _ActionStrip(
                      workspace: workspace,
                      job: selectedJob,
                      isBusy: _isSubmitting,
                      onOpenRoute: () => context.goNamed(
                        AppRoute.workerRoute.nameValue,
                        extra: 0,
                      ),
                      onStart: workspace.profile.role == 'field_worker' &&
                              selectedJob.status == 'scheduled'
                          ? () => _runAction(
                              jobId: selectedJob!.id,
                              action: 'start',
                              successMessage:
                                  '${selectedJob.title} is now in progress.',
                            )
                          : null,
                      onComplete: workspace.profile.role == 'field_worker' &&
                              selectedJob.status == 'in_progress'
                          ? () => _completeJob(selectedJob!)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Schedule and dispatch',
                      child: Column(
                        children: <Widget>[
                          _DetailTile(
                            icon: Icons.place_outlined,
                            label: 'Location',
                            value: selectedJob.locationName,
                          ),
                          _DetailTile(
                            icon: Icons.schedule,
                            label: 'Scheduled start',
                            value: _formatDateTime(selectedJob.scheduledStartAt),
                          ),
                          _DetailTile(
                            icon: Icons.timer_outlined,
                            label: 'Scheduled end',
                            value: _formatDateTime(selectedJob.scheduledEndAt),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Scope of work',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _DetailTile(
                            icon: Icons.flag_outlined,
                            label: 'Priority',
                            value: selectedJob.priority.toUpperCase(),
                            isLast: selectedJob.description == null ||
                                selectedJob.description!.trim().isEmpty,
                          ),
                          if (selectedJob.description != null &&
                              selectedJob.description!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                selectedJob.description!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runAction({
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

    await _runAction(
      jobId: job.id,
      action: request.action,
      notes: request.notes,
      reason: request.reason,
      successMessage: request.action == 'complete'
          ? '${job.title} marked complete.'
          : '${job.title} marked unable to complete.',
    );
  }
}

class _JobHeroCard extends StatelessWidget {
  const _JobHeroCard({required this.job});

  final WorkspaceJobRecord job;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFE53935), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26E53935),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    job.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                JobStatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _HeroPill(
                  icon: Icons.place_outlined,
                  label: job.locationName,
                ),
                _HeroPill(
                  icon: Icons.flag_outlined,
                  label: job.priority.toUpperCase(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.workspace,
    required this.job,
    required this.isBusy,
    required this.onOpenRoute,
    this.onStart,
    this.onComplete,
  });

  final WorkspaceSummary workspace;
  final WorkspaceJobRecord job;
  final bool isBusy;
  final VoidCallback onOpenRoute;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Action center',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              workspace.profile.role == 'field_worker'
                  ? 'Use this screen to start work, close it out, or jump into your active route map.'
                  : 'Management can review job details here while field workers handle execution in the mobile workflow.',
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenRoute,
                    icon: const Icon(Icons.alt_route),
                    label: const Text('Open route'),
                  ),
                ),
                if (onStart != null || onComplete != null) ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : (onStart ?? onComplete),
                      icon: Icon(onStart != null ? Icons.play_arrow : Icons.task_alt),
                      label: Text(onStart != null ? 'Start job' : 'Done job'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4F1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 18, color: const Color(0xFFE53935)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
