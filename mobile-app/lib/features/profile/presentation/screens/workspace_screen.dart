import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/backend_api_client.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/models/workspace_models.dart';
import '../providers/workspace_providers.dart';

class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WorkspaceSummary> workspace = ref.watch(workspaceProvider);

    return workspace.when(
      data: (WorkspaceSummary data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }

          if (data.profile.isManagementRole) {
            context.goNamed(AppRoute.managerOverview.nameValue);
            return;
          }

          context.goNamed(AppRoute.workerJobs.nameValue);
        });

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) {
        final details = _WorkspaceErrorDetails.fromError(error);

        return Scaffold(
          appBar: AppBar(title: const Text('Workspace')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'We could not load your organization workspace.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      details.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (details.hint != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(details.hint!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => ref.invalidate(workspaceProvider),
                        child: const Text('Try again'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          invalidateWorkspaceData(ref);
                          if (context.mounted) {
                            context.goNamed(AppRoute.login.nameValue);
                          }
                        },
                        child: const Text('Log out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WorkspaceErrorDetails {
  const _WorkspaceErrorDetails({required this.message, this.hint});

  final String message;
  final String? hint;

  factory _WorkspaceErrorDetails.fromError(Object error) {
    if (error is BackendApiException) {
      if (error.statusCode == 404) {
        return const _WorkspaceErrorDetails(
          message: 'Requested resource was not found.',
          hint:
              'This usually means your signed-in account does not have a matching profile or organization record in the backend yet.',
        );
      }

      if (error.statusCode == 401) {
        return const _WorkspaceErrorDetails(
          message: 'Your session is no longer valid.',
          hint: 'Log out and sign back in to refresh your account session.',
        );
      }

      return _WorkspaceErrorDetails(message: error.message);
    }

    return _WorkspaceErrorDetails(message: error.toString());
  }
}
