import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/models/workspace_models.dart';

enum WorkerTab { jobs, route, settings }

class WorkerShell extends StatelessWidget {
  const WorkerShell({
    required this.workspace,
    required this.currentTab,
    required this.pageTitle,
    required this.body,
    this.onRefresh,
    super.key,
  });

  final WorkspaceSummary workspace;
  final WorkerTab currentTab;
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
              _WorkerHero(
                title: pageTitle,
                workspace: workspace,
              ),
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
            icon: Icon(Icons.assignment_turned_in_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (int index) {
          switch (WorkerTab.values[index]) {
            case WorkerTab.jobs:
              context.goNamed(
                AppRoute.workerJobs.nameValue,
                extra: currentTab.index,
              );
            case WorkerTab.route:
              context.goNamed(
                AppRoute.workerRoute.nameValue,
                extra: currentTab.index,
              );
            case WorkerTab.settings:
              context.goNamed(
                AppRoute.workerSettings.nameValue,
                extra: currentTab.index,
              );
          }
        },
      ),
    );
  }
}

class _WorkerHero extends StatelessWidget {
  const _WorkerHero({required this.title, required this.workspace});

  final String title;
  final WorkspaceSummary workspace;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFE53935), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26E53935),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                workspace.profile.role.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Welcome back, ${workspace.profile.fullName.split(' ').first}. Your field day is organized here.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _HeroPill(
                    icon: Icons.domain,
                    label: workspace.organization.slug.toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroPill(
                    icon: Icons.bolt,
                    label: workspace.profile.status.toUpperCase(),
                  ),
                ),
              ],
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
