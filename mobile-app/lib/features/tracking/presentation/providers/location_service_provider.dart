import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
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
