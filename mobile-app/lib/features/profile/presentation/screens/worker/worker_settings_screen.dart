import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/app_router.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../tracking/domain/models/location_data.dart';
import '../../../../tracking/presentation/providers/location_service_provider.dart';
import '../../providers/workspace_providers.dart';
import '../../widgets/worker_shell.dart';

class WorkerSettingsScreen extends ConsumerStatefulWidget {
  const WorkerSettingsScreen({super.key});

  @override
  ConsumerState<WorkerSettingsScreen> createState() =>
      _WorkerSettingsScreenState();
}

class _WorkerSettingsScreenState extends ConsumerState<WorkerSettingsScreen> {
  bool _isBusy = false;
  String? _errorMessage;

  Future<void> _enableTracking() async {
    await _runAction(() async {
      final LocationService locationService = ref.read(locationServiceProvider);
      final LocationPermissionState permissionState = await locationService
          .getPermissionState();

      if (permissionState == LocationPermissionState.granted) {
        await locationService.startTracking();
        await ref.read(trackingSyncServiceProvider).start();
        return;
      }

      final LocationPermissionState updatedPermissionState =
          await locationService.requestPermission();

      if (updatedPermissionState == LocationPermissionState.granted) {
        await ref.read(trackingSyncServiceProvider).start();
      }
    });
  }

  Future<void> _startTracking() async {
    await _runAction(() async {
      await ref.read(locationServiceProvider).startTracking();
      await ref.read(trackingSyncServiceProvider).start();
    });
  }

  Future<void> _stopTracking() async {
    await _runAction(() async {
      await ref.read(trackingSyncServiceProvider).stop();
      await ref.read(locationServiceProvider).stopTracking();
    });
  }

  Future<void> _openAppSettings() async {
    await _runAction(() async {
      await ref.read(locationServiceProvider).openAppSettings();
    });
  }

  Future<void> _openLocationSettings() async {
    await _runAction(() async {
      await ref.read(locationServiceProvider).openLocationSettings();
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    invalidateWorkspaceData(ref);
    if (mounted) {
      context.goNamed(AppRoute.login.nameValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceAsync = ref.watch(workspaceProvider);
    final trackingStatusAsync = ref.watch(locationTrackingStatusProvider);
    final latestLocationAsync = ref.watch(locationUpdatesProvider);

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
        onRefresh: () {
          ref.invalidate(workspaceProvider);
          ref.invalidate(workerRouteProvider);
        },
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
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Live tracking',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    trackingStatusAsync.when(
                      data: (status) => Text('Tracking status: ${status.name}'),
                      loading: () => const Text('Checking tracking status...'),
                      error: (Object error, StackTrace stackTrace) =>
                          Text('Tracking status unavailable: $error'),
                    ),
                    const SizedBox(height: 8),
                    latestLocationAsync.when(
                      data: (LocationData value) => Text(
                        'Latest location: ${value.latitude.toStringAsFixed(5)}, ${value.longitude.toStringAsFixed(5)} · ${value.accuracy.toStringAsFixed(0)}m',
                      ),
                      loading: () => const Text('No live location yet.'),
                      error: (Object error, StackTrace stackTrace) =>
                          Text('Live location unavailable: $error'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Workers are marked active whenever a fresh location ping is received. If no ping arrives for 10 minutes, the system marks the worker inactive automatically.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'On iPhone, the app can open Tadester Ops settings for you, but Apple still makes you tap Location inside that screen to change the permission.',
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton(
                          onPressed: _isBusy ? null : _enableTracking,
                          child: const Text('Enable live tracking'),
                        ),
                        OutlinedButton(
                          onPressed: _isBusy ? null : _startTracking,
                          child: const Text('Start tracking'),
                        ),
                        OutlinedButton(
                          onPressed: _isBusy ? null : _stopTracking,
                          child: const Text('Stop tracking'),
                        ),
                        TextButton(
                          onPressed: _isBusy ? null : _openAppSettings,
                          child: const Text('Open app settings'),
                        ),
                        TextButton(
                          onPressed: _isBusy ? null : _openLocationSettings,
                          child: const Text('Device location settings'),
                        ),
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () => context.pushNamed(
                                  AppRoute.permissions.nameValue,
                                ),
                          child: const Text('Open permission page'),
                        ),
                      ],
                    ),
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
                      'Session',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                      ),
                    ),
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
