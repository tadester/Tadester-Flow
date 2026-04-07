import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/models/job.dart';
import '../providers/jobs_provider.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Job>> jobsAsync = ref.watch(jobsProvider);

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
            data: (List<Job> jobs) {
              Job? selectedJob;
              for (final Job job in jobs) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        label: 'Location',
                        value: selectedJob.locationName,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Scheduled',
                        value: DateTimeFormatter.format(
                          selectedJob.scheduledAt,
                        ),
                      ),
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
            color: emphasize ? AppTheme.primaryColor : Colors.black87,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
