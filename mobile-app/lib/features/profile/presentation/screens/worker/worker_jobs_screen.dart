import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/workspace_providers.dart';
import '../../widgets/worker_shell.dart';

class WorkerJobsScreen extends ConsumerWidget {
  const WorkerJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceProvider);
    final jobsAsync = ref.watch(workspaceJobsProvider);

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
      data: (workspace) => WorkerShell(
        workspace: workspace,
        currentTab: WorkerTab.jobs,
        pageTitle: 'Assigned jobs',
        onRefresh: () {
          ref.invalidate(workspaceProvider);
          ref.invalidate(workspaceJobsProvider);
        },
        body: jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Text(
              'Unable to load jobs.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
          data: (jobs) {
            if (jobs.isEmpty) {
              return const Center(child: Text('No assigned jobs right now.'));
            }

            return ListView(
              children: jobs
                  .map(
                    (job) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(job.title),
                        subtitle: Text(
                          '${job.locationName} · ${_formatDateTime(job.scheduledStartAt)}',
                        ),
                        trailing: Chip(
                          label: Text(job.status.replaceAll('_', ' ')),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
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
