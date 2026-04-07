import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../shared/models/job.dart';
import '../../domain/models/workspace_models.dart';
import '../providers/workspace_providers.dart';

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({required this.workspace, super.key});

  final WorkspaceSummary workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Job>> jobsAsync = ref.watch(workspaceJobsProvider);
    final AsyncValue<WorkerRouteSummary> routeAsync = ref.watch(
      workerRouteProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(workspace.organization.name),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              ref.invalidate(workspaceProvider);
              ref.invalidate(workspaceJobsProvider);
              ref.invalidate(workerRouteProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dashboard',
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.goNamed(AppRoute.login.nameValue);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workspaceProvider);
          ref.invalidate(workspaceJobsProvider);
          ref.invalidate(workerRouteProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Welcome back, ${workspace.profile.fullName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your organization: ${workspace.organization.name}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Location tracking'),
                subtitle: const Text(
                  'Open permissions and keep worker pings flowing to the backend.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goNamed(AppRoute.permissions.nameValue),
              ),
            ),
            const SizedBox(height: 16),
            routeAsync.when(
              data: (WorkerRouteSummary route) =>
                  _RouteSummaryCard(route: route),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (Object error, StackTrace stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Route summary unavailable: $error'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Assigned jobs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            jobsAsync.when(
              data: (List<Job> jobs) {
                if (jobs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No assigned jobs right now.'),
                    ),
                  );
                }

                return Column(
                  children: jobs
                      .map(
                        (Job job) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(job.title),
                            subtitle: Text(
                              '${job.locationName} · ${_formatDateTime(job.scheduledAt)}',
                            ),
                            trailing: Chip(
                              label: Text(job.status.replaceAll('_', ' ')),
                            ),
                            onTap: () => context.goNamed(
                              AppRoute.jobDetail.nameValue,
                              pathParameters: <String, String>{'id': job.id},
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Unable to load jobs: $error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(workspaceJobsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.route});

  final WorkerRouteSummary route;

  @override
  Widget build(BuildContext context) {
    final String totalDistanceKm = (route.totalDistance / 1000).toStringAsFixed(
      1,
    );
    final String totalMinutes = (route.totalTime / 60).round().toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Today\'s route',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Stops: ${route.orderedJobs.length}'),
            Text('Distance: $totalDistanceKm km'),
            Text('Travel time: $totalMinutes min'),
            if (route.legs.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ...route.legs.map(
                (RouteLegSummary leg) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Next ETA: ${leg.estimatedArrival.toLocal().hour.toString().padLeft(2, '0')}:${leg.estimatedArrival.toLocal().minute.toString().padLeft(2, '0')} for ${leg.toJobId}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
