import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/models/workspace_models.dart';
import '../../../profile/presentation/providers/workspace_providers.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkspaceJobRecord>> jobsAsync = ref.watch(
      workspaceJobsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Job Detail')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: jobsAsync.when(
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
                if (job.id == jobId) {
                  selectedJob = job;
                  break;
                }
              }

              if (selectedJob == null) {
                return const Center(child: Text('Job not found'));
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: <Widget>[
                      Text(
                        selectedJob.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Status',
                        value: selectedJob.status.replaceAll('_', ' '),
                        emphasize: true,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Priority',
                        value: selectedJob.priority,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Location',
                        value: selectedJob.locationName,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Scheduled start',
                        value: _formatDateTime(selectedJob.scheduledStartAt),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Scheduled end',
                        value: _formatDateTime(selectedJob.scheduledEndAt),
                      ),
                      if (selectedJob.description != null &&
                          selectedJob.description!
                              .trim()
                              .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: 'Description',
                          value: selectedJob.description!,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: emphasize
                ? Theme.of(context).colorScheme.primary
                : Colors.black87,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
