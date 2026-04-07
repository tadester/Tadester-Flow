import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../tracking/presentation/providers/location_service_provider.dart';
import '../../../domain/models/workspace_models.dart';
import '../../providers/workspace_providers.dart';
import '../../widgets/worker_route_map.dart';
import '../../widgets/worker_shell.dart';

class WorkerRouteScreen extends ConsumerStatefulWidget {
  const WorkerRouteScreen({super.key});

  @override
  ConsumerState<WorkerRouteScreen> createState() => _WorkerRouteScreenState();
}

class _WorkerRouteScreenState extends ConsumerState<WorkerRouteScreen> {
  bool _startingTracking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureTrackingIfAlreadyAllowed());
    });
  }

  Future<void> _ensureTrackingIfAlreadyAllowed() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.getPermissionState();

    if (permission == LocationPermissionState.granted) {
      await locationService.startTracking();
      await ref.read(trackingSyncServiceProvider).start();
    }
  }

  Future<void> _startTracking() async {
    setState(() {
      _startingTracking = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final permission = await locationService.getPermissionState();
      if (permission != LocationPermissionState.granted) {
        if (mounted) {
          context.goNamed(AppRoute.permissions.nameValue);
        }
        return;
      }

      await locationService.startTracking();
      await ref.read(trackingSyncServiceProvider).start();
    } finally {
      if (mounted) {
        setState(() {
          _startingTracking = false;
        });
      }
    }
  }

  Future<void> _openNavigation(WorkerRouteStop stop) async {
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse(
            'http://maps.apple.com/?daddr=${stop.latitude},${stop.longitude}&dirflg=d',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${stop.latitude},${stop.longitude}&travelmode=driving',
          );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open navigation app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceAsync = ref.watch(workspaceProvider);
    final routeAsync = ref.watch(workerRouteProvider);
    final trackingStatusAsync = ref.watch(locationTrackingStatusProvider);
    final locationAsync = ref.watch(locationUpdatesProvider);

    return workspaceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Route')),
        body: Center(
          child: Text(
            'Unable to load workspace.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (workspace) => WorkerShell(
        workspace: workspace,
        currentTab: WorkerTab.route,
        pageTitle: 'Route and navigation',
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
                      'Live GPS',
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
                    locationAsync.when(
                      data: (location) => Text(
                        'Current location: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                      ),
                      loading: () =>
                          const Text('Waiting for live location update...'),
                      error: (Object error, StackTrace stackTrace) =>
                          Text('Live location unavailable: $error'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        ElevatedButton.icon(
                          onPressed: _startingTracking ? null : _startTracking,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start live tracking'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.goNamed(AppRoute.permissions.nameValue),
                          icon: const Icon(Icons.security),
                          label: const Text('Permissions'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            routeAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (Object error, StackTrace stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Unable to load route.\n$error'),
                ),
              ),
              data: (route) {
                final nextStop = route.nextStop;
                final liveLocation = locationAsync.asData?.value;

                if (nextStop == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No active route stops for today.'),
                    ),
                  );
                }

                return Column(
                  children: <Widget>[
                    if (!Env.hasGoogleMapsKey)
                      Card(
                        color: const Color(0xFFFFF4F4),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Google Maps is not fully configured yet. Add GOOGLE_MAPS_API_KEY to mobile-app/.env, Android local.properties, and the iOS xcconfig files to render the in-app map.',
                          ),
                        ),
                      )
                    else
                      WorkerRouteMap(
                        route: route,
                        currentLocation: liveLocation,
                      ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Next stop',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              nextStop.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${nextStop.locationName} · ${_formatDateTime(nextStop.scheduledAt)}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Distance today: ${(route.totalDistance / 1000).toStringAsFixed(1)} km',
                            ),
                            Text(
                              'Travel time: ${(route.totalTime / 60).round()} min',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _openNavigation(nextStop),
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navigate to next stop'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...route.orderedJobs.map(
                      (stop) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(stop.title),
                          subtitle: Text(
                            '${stop.locationName} · ${_formatDateTime(stop.scheduledAt)}',
                          ),
                          trailing: Chip(
                            label: Text(stop.status.replaceAll('_', ' ')),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
