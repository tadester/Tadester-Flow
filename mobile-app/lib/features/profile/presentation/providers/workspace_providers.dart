import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/backend_api_client.dart';
import '../../../../core/services/google_directions_service.dart';
import '../../../../features/tracking/domain/models/location_data.dart';
import '../../../../features/tracking/presentation/providers/location_service_provider.dart';
import '../../data/workspace_repository.dart';
import '../../domain/models/workspace_models.dart';

enum RouteDisplayMode { scheduled, optimized }

class WorkerRouteDisplayModeNotifier extends Notifier<RouteDisplayMode> {
  @override
  RouteDisplayMode build() => RouteDisplayMode.scheduled;

  void setMode(RouteDisplayMode mode) {
    state = mode;
  }
}

final Provider<WorkspaceRepository> workspaceRepositoryProvider =
    Provider<WorkspaceRepository>((Ref ref) {
      return WorkspaceRepository(apiClient: ref.read(backendApiClientProvider));
    });

final FutureProvider<WorkspaceSummary> workspaceProvider =
    FutureProvider<WorkspaceSummary>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getWorkspace();
    });

final FutureProvider<List<EmployeeRecord>> employeesProvider =
    FutureProvider<List<EmployeeRecord>>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getEmployees();
    });

final FutureProvider<List<LocationRecord>> workspaceLocationsProvider =
    FutureProvider<List<LocationRecord>>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getLocations();
    });

final FutureProvider<List<WorkspaceJobRecord>> workspaceJobsProvider =
    FutureProvider<List<WorkspaceJobRecord>>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getJobs();
    });

final FutureProvider<WorkerRouteSummary> workerRouteProvider =
    FutureProvider<WorkerRouteSummary>((Ref ref) {
      return ref
          .read(workspaceRepositoryProvider)
          .getMyRoute(date: _todayIsoDate());
    });

final NotifierProvider<WorkerRouteDisplayModeNotifier, RouteDisplayMode>
    workerRouteDisplayModeProvider =
    NotifierProvider<WorkerRouteDisplayModeNotifier, RouteDisplayMode>(
      WorkerRouteDisplayModeNotifier.new,
    );

final Provider<AsyncValue<WorkerRouteSummary>> baseWorkerRouteProvider =
    Provider<AsyncValue<WorkerRouteSummary>>((Ref ref) {
      final AsyncValue<WorkerRouteSummary> routeAsync = ref.watch(
        workerRouteProvider,
      );
      final AsyncValue<List<WorkspaceJobRecord>> jobsAsync = ref.watch(
        workspaceJobsProvider,
      );

      return routeAsync.when(
        data: (WorkerRouteSummary route) {
          if (route.orderedJobs.isNotEmpty) {
            return AsyncValue<WorkerRouteSummary>.data(route);
          }

          return jobsAsync.when(
            data: (List<WorkspaceJobRecord> jobs) {
              return AsyncValue<WorkerRouteSummary>.data(
                _routeFromWorkspaceJobs(jobs),
              );
            },
            loading: () => const AsyncValue<WorkerRouteSummary>.loading(),
            error: (Object error, StackTrace stackTrace) =>
                AsyncValue<WorkerRouteSummary>.error(error, stackTrace),
          );
        },
        loading: () => jobsAsync.when(
          data: (List<WorkspaceJobRecord> jobs) {
            if (jobs.isEmpty) {
              return const AsyncValue<WorkerRouteSummary>.loading();
            }
            return AsyncValue<WorkerRouteSummary>.data(
              _routeFromWorkspaceJobs(jobs),
            );
          },
          loading: () => const AsyncValue<WorkerRouteSummary>.loading(),
          error: (Object error, StackTrace stackTrace) =>
              AsyncValue<WorkerRouteSummary>.error(error, stackTrace),
        ),
        error: (Object error, StackTrace stackTrace) => jobsAsync.when(
          data: (List<WorkspaceJobRecord> jobs) {
            if (jobs.isEmpty) {
              return AsyncValue<WorkerRouteSummary>.error(error, stackTrace);
            }
            return AsyncValue<WorkerRouteSummary>.data(
              _routeFromWorkspaceJobs(jobs),
            );
          },
          loading: () => const AsyncValue<WorkerRouteSummary>.loading(),
          error: (Object fallbackError, StackTrace fallbackStackTrace) =>
              AsyncValue<WorkerRouteSummary>.error(error, stackTrace),
        ),
      );
    });

final Provider<AsyncValue<WorkerRouteSummary>> displayedWorkerRouteProvider =
    Provider<AsyncValue<WorkerRouteSummary>>((Ref ref) {
      final AsyncValue<WorkerRouteSummary> routeAsync = ref.watch(
        baseWorkerRouteProvider,
      );
      final RouteDisplayMode mode = ref.watch(workerRouteDisplayModeProvider);
      final LocationData? location = ref.watch(locationUpdatesProvider).asData?.value;

      return routeAsync.whenData((WorkerRouteSummary route) {
        if (mode == RouteDisplayMode.scheduled || location == null) {
          return route;
        }

        return _optimizeWorkerRoute(route, location);
      });
    });

final Provider<GoogleDirectionsService> googleDirectionsServiceProvider =
    Provider<GoogleDirectionsService>((Ref ref) {
      return GoogleDirectionsService();
    });

final FutureProvider<RouteDirectionsData?> workerRouteDirectionsProvider =
    FutureProvider<RouteDirectionsData?>((Ref ref) async {
      final WorkerRouteSummary? route = ref
          .watch(displayedWorkerRouteProvider)
          .asData
          ?.value;
      final LocationData? location = ref.watch(locationUpdatesProvider).asData?.value;

      if (route == null || route.orderedJobs.isEmpty || location == null) {
        return null;
      }

      final List<WorkerRouteStop> mappableStops = route.orderedJobs
          .where(
            (WorkerRouteStop stop) =>
                stop.latitude != 0 || stop.longitude != 0,
          )
          .toList(growable: false);

      if (mappableStops.isEmpty) {
        return null;
      }

      return ref.read(googleDirectionsServiceProvider).buildRoute(
        origin: RouteCoordinate(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
        stops: mappableStops
            .map(
              (WorkerRouteStop stop) => RouteCoordinate(
                latitude: stop.latitude,
                longitude: stop.longitude,
              ),
            )
            .toList(growable: false),
      );
    });

void invalidateWorkspaceData(WidgetRef ref) {
  ref.invalidate(workspaceProvider);
  ref.invalidate(employeesProvider);
  ref.invalidate(workspaceLocationsProvider);
  ref.invalidate(workspaceJobsProvider);
  ref.invalidate(workerRouteProvider);
  ref.invalidate(baseWorkerRouteProvider);
  ref.invalidate(displayedWorkerRouteProvider);
  ref.invalidate(workerRouteDirectionsProvider);
}

WorkerRouteSummary _routeFromWorkspaceJobs(List<WorkspaceJobRecord> jobs) {
  final List<WorkspaceJobRecord> relevantJobs = jobs
      .where(
        (WorkspaceJobRecord job) =>
            job.status == 'scheduled' || job.status == 'in_progress',
      )
      .toList(growable: false);

  final List<WorkspaceJobRecord> source = relevantJobs.isNotEmpty
      ? relevantJobs
      : jobs;

  final List<WorkspaceJobRecord> ordered = <WorkspaceJobRecord>[...source]
    ..sort(
      (WorkspaceJobRecord left, WorkspaceJobRecord right) {
        final int scheduledComparison = left.scheduledStartAt.compareTo(
          right.scheduledStartAt,
        );
        if (scheduledComparison != 0) {
          return scheduledComparison;
        }
        return left.id.compareTo(right.id);
      },
    );

  final List<WorkerRouteStop> stops = ordered
      .map(
        (WorkspaceJobRecord job) => WorkerRouteStop(
          id: job.id,
          title: job.title,
          status: job.status,
          locationName: job.locationName,
          latitude: job.latitude,
          longitude: job.longitude,
          scheduledAt: job.scheduledStartAt,
        ),
      )
      .toList(growable: false);

  return WorkerRouteSummary(
    orderedJobs: stops,
    legs: const <RouteLegSummary>[],
    totalDistance: 0,
    totalTime: 0,
  );
}

WorkerRouteSummary _optimizeWorkerRoute(
  WorkerRouteSummary route,
  LocationData location,
) {
  final List<WorkerRouteStop> remainingStops = List<WorkerRouteStop>.from(
    route.orderedJobs,
  );
  if (remainingStops.length < 2) {
    return route;
  }

  final List<WorkerRouteStop> optimizedStops = <WorkerRouteStop>[];
  double currentLatitude = location.latitude;
  double currentLongitude = location.longitude;

  while (remainingStops.isNotEmpty) {
    remainingStops.sort((WorkerRouteStop left, WorkerRouteStop right) {
      final double leftDistance = _distanceMeters(
        currentLatitude,
        currentLongitude,
        left.latitude,
        left.longitude,
      );
      final double rightDistance = _distanceMeters(
        currentLatitude,
        currentLongitude,
        right.latitude,
        right.longitude,
      );

      if (leftDistance == rightDistance) {
        return left.id.compareTo(right.id);
      }

      return leftDistance.compareTo(rightDistance);
    });

    final WorkerRouteStop nextStop = remainingStops.removeAt(0);
    optimizedStops.add(nextStop);
    currentLatitude = nextStop.latitude;
    currentLongitude = nextStop.longitude;
  }

  final DateTime now = DateTime.now();
  final List<RouteLegSummary> legs = <RouteLegSummary>[];
  int totalDistance = 0;
  int totalDuration = 0;
  double fromLatitude = location.latitude;
  double fromLongitude = location.longitude;
  String? fromJobId;

  for (final WorkerRouteStop stop in optimizedStops) {
    final int distanceMeters = _distanceMeters(
      fromLatitude,
      fromLongitude,
      stop.latitude,
      stop.longitude,
    ).round();
    final int durationSeconds = (distanceMeters / 13.89).round();

    totalDistance += distanceMeters;
    totalDuration += durationSeconds;
    legs.add(
      RouteLegSummary(
        fromJobId: fromJobId,
        toJobId: stop.id,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        estimatedArrival: now.add(Duration(seconds: totalDuration)),
      ),
    );

    fromLatitude = stop.latitude;
    fromLongitude = stop.longitude;
    fromJobId = stop.id;
  }

  return WorkerRouteSummary(
    orderedJobs: optimizedStops,
    legs: legs,
    totalDistance: totalDistance,
    totalTime: totalDuration,
  );
}

double _distanceMeters(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  const double earthRadiusMeters = 6371000;
  final double deltaLatitude = _degreesToRadians(endLatitude - startLatitude);
  final double deltaLongitude = _degreesToRadians(endLongitude - startLongitude);
  final double startLatitudeRadians = _degreesToRadians(startLatitude);
  final double endLatitudeRadians = _degreesToRadians(endLatitude);

  final double haversine =
      math.pow(math.sin(deltaLatitude / 2), 2).toDouble() +
      math.pow(math.sin(deltaLongitude / 2), 2).toDouble() *
          math.cos(startLatitudeRadians) *
          math.cos(endLatitudeRadians);

  final double arc =
      2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  return earthRadiusMeters * arc;
}

String _todayIsoDate() {
  final DateTime now = DateTime.now();
  final String year = now.year.toString().padLeft(4, '0');
  final String month = now.month.toString().padLeft(2, '0');
  final String day = now.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

double _degreesToRadians(double degrees) => degrees * 0.017453292519943295;
