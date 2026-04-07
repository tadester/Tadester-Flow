import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/workspace_providers.dart';
import '../../widgets/worker_shell.dart';

class WorkerSettingsScreen extends ConsumerWidget {
  const WorkerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceProvider);

    return workspaceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Text(
            'Unable to load settings.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (workspace) => WorkerShell(
        workspace: workspace,
        currentTab: WorkerTab.settings,
        pageTitle: 'Settings',
        onRefresh: () => ref.invalidate(workspaceProvider),
        body: ListView(
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Organization',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(workspace.organization.name),
                    Text('Role: ${workspace.profile.role}'),
                    Text('Status: ${workspace.profile.status}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(workspace.profile.fullName),
                    Text(workspace.profile.email),
                    if (workspace.profile.phone != null &&
                        workspace.profile.phone!.isNotEmpty)
                      Text(workspace.profile.phone!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
