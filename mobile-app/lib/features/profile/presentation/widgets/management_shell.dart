import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/models/workspace_models.dart';

enum ManagementTab { overview, jobs, workers, settings }

class ManagementShell extends StatelessWidget {
  const ManagementShell({
    required this.workspace,
    required this.currentTab,
    required this.pageTitle,
    required this.body,
    this.onRefresh,
    super.key,
  });

  final WorkspaceSummary workspace;
  final ManagementTab currentTab;
  final String pageTitle;
  final Widget body;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workspace.organization.name),
        actions: <Widget>[
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: <Widget>[
              _ManagementHero(title: pageTitle, workspace: workspace),
              const SizedBox(height: 16),
              Expanded(child: body),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Workers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (int index) {
          switch (ManagementTab.values[index]) {
            case ManagementTab.overview:
              context.goNamed(
                AppRoute.managerOverview.nameValue,
                extra: currentTab.index,
              );
            case ManagementTab.jobs:
              context.goNamed(
                AppRoute.managerJobs.nameValue,
                extra: currentTab.index,
              );
            case ManagementTab.workers:
              context.goNamed(
                AppRoute.managerWorkers.nameValue,
                extra: currentTab.index,
              );
            case ManagementTab.settings:
              context.goNamed(
                AppRoute.managerSettings.nameValue,
                extra: currentTab.index,
              );
          }
        },
      ),
    );
  }
}

class _ManagementHero extends StatelessWidget {
  const _ManagementHero({required this.title, required this.workspace});

  final String title;
  final WorkspaceSummary workspace;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF221A17),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Signed in as ${workspace.profile.fullName} (${workspace.profile.role.replaceAll('_', ' ')}).',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _ManagementChip(label: workspace.organization.slug.toUpperCase()),
                _ManagementChip(label: '${workspace.metrics.activeJobsCount} active jobs'),
                _ManagementChip(label: '${workspace.metrics.fieldWorkersCount} field workers'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementChip extends StatelessWidget {
  const _ManagementChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
