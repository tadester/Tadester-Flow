import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/location_data.dart';
import 'tracking_repository.dart';

class TrackingSyncService {
  TrackingSyncService({
    required Stream<LocationData> locationStream,
    required TrackingRepository trackingRepository,
  }) : _locationStream = locationStream,
       _trackingRepository = trackingRepository;

  final Stream<LocationData> _locationStream;
  final TrackingRepository _trackingRepository;

  StreamSubscription<LocationData>? _subscription;

  Future<void> start() async {
    if (_subscription != null) {
      return;
    }

    _subscription = _locationStream.listen((LocationData location) {
      unawaited(_sendPingSafely(location));
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _sendPingSafely(LocationData location) async {
    try {
      await _trackingRepository.sendPing(location);
    } catch (error, stackTrace) {
      debugPrint('Tracking ping upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
