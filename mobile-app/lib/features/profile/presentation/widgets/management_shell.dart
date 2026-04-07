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
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(pageTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Signed in as ${workspace.profile.fullName} (${workspace.profile.role}).',
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
            icon: Icon(Icons.space_dashboard),
            label: 'Overview',
          ),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Workers'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
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
