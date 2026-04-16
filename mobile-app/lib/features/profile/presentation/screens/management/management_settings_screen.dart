import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/app_router.dart';
import '../../../../auth/presentation/providers/auth_state_provider.dart';
import '../../providers/workspace_providers.dart';
import '../../widgets/management_shell.dart';

class ManagementSettingsScreen extends ConsumerWidget {
  const ManagementSettingsScreen({super.key});

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
      data: (workspace) => ManagementShell(
        workspace: workspace,
        currentTab: ManagementTab.settings,
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
                    Text('Name: ${workspace.organization.name}'),
                    Text('Slug: ${workspace.organization.slug}'),
                    Text('Status: ${workspace.organization.status}'),
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
                    Text('Name: ${workspace.profile.fullName}'),
                    Text('Email: ${workspace.profile.email}'),
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      invalidateWorkspaceData(ref);
                      if (context.mounted) {
                        context.goNamed(AppRoute.login.nameValue);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
