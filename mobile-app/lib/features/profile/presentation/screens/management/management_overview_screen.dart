import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/app_router.dart';
import '../../providers/workspace_providers.dart';
import '../../widgets/management_shell.dart';

class ManagementOverviewScreen extends ConsumerWidget {
  const ManagementOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceProvider);

    return workspaceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Management overview')),
        body: Center(
          child: Text(
            'Unable to load overview.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (workspace) => ManagementShell(
        workspace: workspace,
        currentTab: ManagementTab.overview,
        pageTitle: 'Operations overview',
        onRefresh: () => ref.invalidate(workspaceProvider),
        body: ListView(
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _MetricCard(
                  label: 'Employees',
                  value: workspace.metrics.employeesCount.toString(),
                ),
                _MetricCard(
                  label: 'Workers',
                  value: workspace.metrics.fieldWorkersCount.toString(),
                ),
                _MetricCard(
                  label: 'Locations',
                  value: workspace.metrics.locationsCount.toString(),
                ),
                _MetricCard(
                  label: 'Active jobs',
                  value: workspace.metrics.activeJobsCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ActionCard(
              title: 'Manage jobs',
              subtitle:
                  'Create work, assign people, and run proximity-based auto assignment.',
              icon: Icons.assignment,
              onTap: () => context.goNamed(AppRoute.managerJobs.nameValue),
            ),
            _ActionCard(
              title: 'View workers',
              subtitle:
                  'See your organization roster and focus on field workers separately from management roles.',
              icon: Icons.people,
              onTap: () => context.goNamed(AppRoute.managerWorkers.nameValue),
            ),
            _ActionCard(
              title: 'Organization settings',
              subtitle: 'Review organization details and account information.',
              icon: Icons.settings,
              onTap: () => context.goNamed(AppRoute.managerSettings.nameValue),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
