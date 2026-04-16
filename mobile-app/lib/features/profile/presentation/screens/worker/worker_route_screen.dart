import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/services/google_directions_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../shared/widgets/job_status_badge.dart';
import '../../../../jobs/presentation/widgets/worker_job_action_sheet.dart';
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureTrackingIfAlreadyAllowed());
    });
  }

  Future<void> _ensureTrackingIfAlreadyAllowed() async {
    final LocationService locationService = ref.read(locationServiceProvider);
    final LocationPermissionState permission = await locationService
        .getPermissionState();

    if (permission == LocationPermissionState.granted) {
      await locationService.startTracking();
      await ref.read(trackingSyncServiceProvider).start();
    }
  }

  Future<void> _openNavigation(WorkerRouteStop stop) async {
    final Uri uri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse(
            'http://maps.apple.com/?daddr=${stop.latitude},${stop.longitude}&dirflg=d',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${stop.latitude},${stop.longitude}&travelmode=driving',
          );

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open navigation app.')),
      );
    }
  }

  Future<void> _runJobAction({
    required String jobId,
    required String action,
    required String successMessage,
    String? notes,
    String? reason,
  }) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .runWorkerJobAction(
            jobId: jobId,
            action: action,
            notes: notes,
            reason: reason,
          );
      invalidateWorkspaceData(ref);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update route stop. $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleNextStop(WorkerRouteStop stop) async {
    if (stop.status == 'scheduled') {
      await _runJobAction(
        jobId: stop.id,
        action: 'start',
        successMessage: '${stop.title} started.',
      );
      return;
    }

    if (stop.status == 'in_progress') {
      final WorkerJobActionRequest? request = await showWorkerJobActionSheet(
        context,
        jobTitle: stop.title,
      );
      if (request == null) {
        return;
      }

      await _runJobAction(
        jobId: stop.id,
        action: request.action,
        notes: request.notes,
        reason: request.reason,
        successMessage: request.action == 'complete'
            ? '${stop.title} marked complete. Routing next stop.'
            : '${stop.title} marked unable to complete. Routing next stop.',
      );
      return;
    }

    ref.invalidate(workerRouteProvider);
    ref.invalidate(workerRouteDirectionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WorkspaceSummary> workspaceAsync = ref.watch(
      workspaceProvider,
    );
    final AsyncValue<WorkerRouteSummary> displayedRouteAsync = ref.watch(
      displayedWorkerRouteProvider,
    );
    final AsyncValue<RouteDirectionsData?> directionsAsync = ref.watch(
      workerRouteDirectionsProvider,
    );
    final AsyncValue<LocationTrackingStatus> trackingStatusAsync = ref.watch(
      locationTrackingStatusProvider,
    );
    final AsyncValue<dynamic> locationAsync = ref.watch(locationUpdatesProvider);
    final RouteDisplayMode displayMode = ref.watch(workerRouteDisplayModeProvider);

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
      data: (WorkspaceSummary workspace) => WorkerShell(
        workspace: workspace,
        currentTab: WorkerTab.route,
        pageTitle: 'Live route',
        onRefresh: () => invalidateWorkspaceData(ref),
        body: displayedRouteAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Unable to load route.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => invalidateWorkspaceData(ref),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (WorkerRouteSummary route) {
            final WorkerRouteStop? nextStop = route.nextStop;
            final dynamic liveLocation = locationAsync.asData?.value;
            final RouteDirectionsData? directions = directionsAsync.asData?.value;
            final int distanceMeters =
                directions?.totalDistanceMeters ?? route.totalDistance;
            final int durationSeconds =
                directions?.totalDurationSeconds ?? route.totalTime;

            if (nextStop == null) {
              return ListView(
                children: <Widget>[
                  _ModeToggle(
                    selectedMode: displayMode,
                    onChanged: (RouteDisplayMode mode) {
                      ref
                          .read(workerRouteDisplayModeProvider.notifier)
                          .setMode(mode);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (Env.hasGoogleMapsKey)
                    WorkerRouteMap(
                      route: route,
                      currentLocation: liveLocation,
                      directions: directions,
                    )
                  else
                    Card(
                      color: const Color(0xFFFFF4F4),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Google Maps is not fully configured yet. Add GOOGLE_MAPS_API_KEY to mobile-app/.env and your native configs to render the in-app map.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _EmptyRouteCard(
                    onOpenJobs: () => context.goNamed(
                      AppRoute.workerJobs.nameValue,
                      extra: WorkerTab.route.index,
                    ),
                  ),
                ],
              );
            }

            return ListView(
              children: <Widget>[
                _ModeToggle(
                  selectedMode: displayMode,
                  onChanged: (RouteDisplayMode mode) {
                    ref
                        .read(workerRouteDisplayModeProvider.notifier)
                        .setMode(mode);
                  },
                ),
                const SizedBox(height: 16),
                if (!Env.hasGoogleMapsKey)
                  Card(
                    color: const Color(0xFFFFF4F4),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Google Maps is not fully configured yet. Add GOOGLE_MAPS_API_KEY to mobile-app/.env and your native configs to render the in-app map.',
                      ),
                    ),
                  )
                else
                  WorkerRouteMap(
                    route: route,
                    currentLocation: liveLocation,
                    directions: directions,
                  ),
                const SizedBox(height: 16),
                _RouteSummaryCard(
                  nextStop: nextStop,
                  trackingStatus: trackingStatusAsync.asData?.value,
                  distanceMeters: distanceMeters,
                  durationSeconds: durationSeconds,
                  isBusy: _isSubmitting,
                  onNavigate: () => _openNavigation(nextStop),
                  onNextStop: () => _handleNextStop(nextStop),
                ),
                const SizedBox(height: 16),
                Text(
                  'Stop order',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...route.orderedJobs.asMap().entries.map(
                  (MapEntry<int, WorkerRouteStop> entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RouteStopCard(
                      index: entry.key,
                      stop: entry.value,
                      onOpen: () => context.pushNamed(
                        AppRoute.jobDetail.nameValue,
                        pathParameters: <String, String>{'id': entry.value.id},
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.selectedMode, required this.onChanged});

  final RouteDisplayMode selectedMode;
  final ValueChanged<RouteDisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Route mode', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<RouteDisplayMode>(
              segments: const <ButtonSegment<RouteDisplayMode>>[
                ButtonSegment<RouteDisplayMode>(
                  value: RouteDisplayMode.scheduled,
                  icon: Icon(Icons.schedule),
                  label: Text('Scheduled'),
                ),
                ButtonSegment<RouteDisplayMode>(
                  value: RouteDisplayMode.optimized,
                  icon: Icon(Icons.auto_awesome),
                  label: Text('Optimal'),
                ),
              ],
              selected: <RouteDisplayMode>{selectedMode},
              onSelectionChanged: (Set<RouteDisplayMode> value) {
                onChanged(value.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.nextStop,
    required this.trackingStatus,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isBusy,
    required this.onNavigate,
    required this.onNextStop,
  });

  final WorkerRouteStop nextStop;
  final LocationTrackingStatus? trackingStatus;
  final int distanceMeters;
  final int durationSeconds;
  final bool isBusy;
  final VoidCallback onNavigate;
  final VoidCallback onNextStop;

  @override
  Widget build(BuildContext context) {
    final String primaryLabel = nextStop.status == 'scheduled'
        ? 'Start stop'
        : 'Next stop';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    nextStop.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                JobStatusBadge(status: nextStop.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(nextStop.locationName),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _RouteMetricChip(
                  icon: Icons.route,
                  label: '${(distanceMeters / 1000).toStringAsFixed(1)} km total',
                ),
                _RouteMetricChip(
                  icon: Icons.timer_outlined,
                  label: '${(durationSeconds / 60).round()} min drive',
                ),
                _RouteMetricChip(
                  icon: Icons.gps_fixed,
                  label: 'Tracking ${trackingStatus?.name ?? 'unknown'}',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onNextStop,
                    icon: Icon(
                      nextStop.status == 'scheduled'
                          ? Icons.play_arrow
                          : Icons.skip_next,
                    ),
                    label: Text(primaryLabel),
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

class _RouteMetricChip extends StatelessWidget {
  const _RouteMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFE53935)),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _RouteStopCard extends StatelessWidget {
  const _RouteStopCard({
    required this.index,
    required this.stop,
    required this.onOpen,
  });

  final int index;
  final WorkerRouteStop stop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: const Color(0xFFFFE4DA),
                foregroundColor: const Color(0xFFE53935),
                child: Text('${index + 1}'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stop.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(stop.locationName),
                    const SizedBox(height: 4),
                    Text(_formatDateTime(stop.scheduledAt)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              JobStatusBadge(status: stop.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRouteCard extends StatelessWidget {
  const _EmptyRouteCard({required this.onOpenJobs});

  final VoidCallback onOpenJobs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.map_outlined, size: 54),
            const SizedBox(height: 16),
            Text(
              'No route available right now',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Once you have active jobs, this page will draw the order on the map and guide your next stop.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenJobs,
              icon: const Icon(Icons.assignment),
              label: const Text('Open jobs'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
