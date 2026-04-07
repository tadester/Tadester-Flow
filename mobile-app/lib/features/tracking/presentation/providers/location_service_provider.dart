import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/backend_api_client.dart';
import '../../../../core/services/location_service.dart';
import '../../data/tracking_repository.dart';
import '../../data/tracking_sync_service.dart';
import '../../domain/models/location_data.dart';

final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>((Ref ref) {
      final LocationService service = LocationService();
      ref.onDispose(() {
        service.dispose();
      });
      return service;
    });

final StreamProvider<LocationTrackingStatus> locationTrackingStatusProvider =
    StreamProvider<LocationTrackingStatus>((Ref ref) {
      final LocationService service = ref.watch(locationServiceProvider);
      return service.trackingStatusStream;
    });

final StreamProvider<LocationData> locationUpdatesProvider =
    StreamProvider<LocationData>((Ref ref) {
      final LocationService service = ref.watch(locationServiceProvider);
      return service.locationStream;
    });

final Provider<TrackingRepository> trackingRepositoryProvider =
    Provider<TrackingRepository>((Ref ref) {
      final BackendApiClient apiClient = ref.watch(backendApiClientProvider);
      return TrackingRepository(apiClient: apiClient);
    });

final Provider<TrackingSyncService> trackingSyncServiceProvider =
    Provider<TrackingSyncService>((Ref ref) {
      final LocationService locationService = ref.watch(locationServiceProvider);
      final TrackingRepository trackingRepository = ref.watch(
        trackingRepositoryProvider,
      );
      final TrackingSyncService service = TrackingSyncService(
        locationStream: locationService.locationStream,
        trackingRepository: trackingRepository,
      );

      ref.onDispose(() {
        unawaited(service.stop());
      });

      return service;
    });
