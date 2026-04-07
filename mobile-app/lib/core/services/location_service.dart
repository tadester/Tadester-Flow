import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

import '../../features/tracking/domain/models/location_data.dart';

enum LocationPermissionState { granted, denied, deniedForever, serviceDisabled }

enum LocationTrackingStatus {
  idle,
  tracking,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  stopped,
}

abstract class LocationPermissionGateway {
  Future<permission_handler.PermissionStatus> checkStatus();
  Future<permission_handler.PermissionStatus> requestPermission();
  Future<bool> openSettings();
}

class PermissionHandlerGateway implements LocationPermissionGateway {
  @override
  Future<permission_handler.PermissionStatus> checkStatus() {
    return permission_handler.Permission.locationWhenInUse.status;
  }

  @override
  Future<permission_handler.PermissionStatus> requestPermission() {
    return permission_handler.Permission.locationWhenInUse.request();
  }

  @override
  Future<bool> openSettings() {
    return permission_handler.openAppSettings();
  }
}

abstract class DeviceLocationGateway {
  Future<bool> isLocationServiceEnabled();
  Stream<ServiceStatus> getServiceStatusStream();
  Stream<Position> getPositionStream(LocationSettings settings);
  Future<bool> openLocationSettings();
}

class GeolocatorGateway implements DeviceLocationGateway {
  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }

  @override
  Stream<Position> getPositionStream(LocationSettings settings) {
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}

class LocationService with WidgetsBindingObserver {
  LocationService({
    LocationPermissionGateway? permissionGateway,
    DeviceLocationGateway? deviceLocationGateway,
  }) : _permissionGateway = permissionGateway ?? PermissionHandlerGateway(),
       _deviceLocationGateway = deviceLocationGateway ?? GeolocatorGateway() {
    WidgetsBinding.instance.addObserver(this);
    _serviceStatusSubscription = _deviceLocationGateway
        .getServiceStatusStream()
        .listen(_handleServiceStatusChange);
  }

  static const int trackingIntervalSeconds = 60;
  static const int trackingDistanceFilterMeters = 25;

  final LocationPermissionGateway _permissionGateway;
  final DeviceLocationGateway _deviceLocationGateway;
  final StreamController<LocationData> _locationStreamController =
      StreamController<LocationData>.broadcast();
  final StreamController<LocationTrackingStatus> _statusStreamController =
      StreamController<LocationTrackingStatus>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  LocationTrackingStatus _trackingStatus = LocationTrackingStatus.idle;

  Stream<LocationData> get locationStream => _locationStreamController.stream;
  Stream<LocationTrackingStatus> get trackingStatusStream =>
      _statusStreamController.stream;
  LocationTrackingStatus get trackingStatus => _trackingStatus;

  Future<LocationPermissionState> getPermissionState() async {
    final bool servicesEnabled = await _deviceLocationGateway
        .isLocationServiceEnabled();
    if (!servicesEnabled) {
      return LocationPermissionState.serviceDisabled;
    }

    final permission_handler.PermissionStatus permissionStatus =
        await _permissionGateway.checkStatus();
    return _mapPermissionStatus(permissionStatus);
  }

  Future<LocationPermissionState> requestPermission() async {
    final bool servicesEnabled = await _deviceLocationGateway
        .isLocationServiceEnabled();
    if (!servicesEnabled) {
      _updateTrackingStatus(LocationTrackingStatus.serviceDisabled);
      return LocationPermissionState.serviceDisabled;
    }

    final permission_handler.PermissionStatus permissionStatus =
        await _permissionGateway.requestPermission();
    final LocationPermissionState permissionState = _mapPermissionStatus(
      permissionStatus,
    );

    switch (permissionState) {
      case LocationPermissionState.granted:
        await startTracking();
      case LocationPermissionState.denied:
        await stopTracking();
        _updateTrackingStatus(LocationTrackingStatus.permissionDenied);
      case LocationPermissionState.deniedForever:
        await stopTracking();
        _updateTrackingStatus(LocationTrackingStatus.permissionDeniedForever);
      case LocationPermissionState.serviceDisabled:
        await stopTracking();
        _updateTrackingStatus(LocationTrackingStatus.serviceDisabled);
    }

    return permissionState;
  }

  Future<void> startTracking() async {
    final LocationPermissionState permissionState = await getPermissionState();
    if (permissionState != LocationPermissionState.granted) {
      _syncTrackingStatusWithPermission(permissionState);
      return;
    }

    if (_positionSubscription != null) {
      _updateTrackingStatus(LocationTrackingStatus.tracking);
      return;
    }

    final LocationSettings settings = _buildLocationSettings();

    _positionSubscription = _deviceLocationGateway
        .getPositionStream(settings)
        .listen(
          (Position position) {
            _locationStreamController.add(
              LocationData(
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                timestamp: position.timestamp,
              ),
            );
            _updateTrackingStatus(LocationTrackingStatus.tracking);
          },
          onError: (Object error, StackTrace stackTrace) async {
            final LocationPermissionState permissionState =
                await getPermissionState();
            await stopTracking();
            _syncTrackingStatusWithPermission(permissionState);
          },
        );

    _updateTrackingStatus(LocationTrackingStatus.tracking);
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (_trackingStatus == LocationTrackingStatus.tracking) {
      _updateTrackingStatus(LocationTrackingStatus.stopped);
    }
  }

  Future<void> resumeTracking() async {
    final LocationPermissionState permissionState = await getPermissionState();
    if (permissionState == LocationPermissionState.granted) {
      await startTracking();
      return;
    }

    await stopTracking();
    _syncTrackingStatusWithPermission(permissionState);
  }

  Future<bool> openAppSettings() {
    return _permissionGateway.openSettings();
  }

  Future<bool> openLocationSettings() {
    return _deviceLocationGateway.openLocationSettings();
  }

  Future<void> prepareBackgroundTrackingHook() async {
    // Reserved for future background tracking integration.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(resumeTracking());
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_positionSubscription?.cancel());
    unawaited(_serviceStatusSubscription?.cancel());
    unawaited(_locationStreamController.close());
    unawaited(_statusStreamController.close());
  }

  void _handleServiceStatusChange(ServiceStatus status) {
    if (status == ServiceStatus.enabled) {
      unawaited(resumeTracking());
      return;
    }

    unawaited(stopTracking());
    _updateTrackingStatus(LocationTrackingStatus.serviceDisabled);
  }

  LocationPermissionState _mapPermissionStatus(
    permission_handler.PermissionStatus status,
  ) {
    if (status.isGranted || status.isLimited) {
      return LocationPermissionState.granted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionState.deniedForever;
    }

    return LocationPermissionState.denied;
  }

  void _syncTrackingStatusWithPermission(
    LocationPermissionState permissionState,
  ) {
    switch (permissionState) {
      case LocationPermissionState.granted:
        _updateTrackingStatus(LocationTrackingStatus.tracking);
      case LocationPermissionState.denied:
        _updateTrackingStatus(LocationTrackingStatus.permissionDenied);
      case LocationPermissionState.deniedForever:
        _updateTrackingStatus(LocationTrackingStatus.permissionDeniedForever);
      case LocationPermissionState.serviceDisabled:
        _updateTrackingStatus(LocationTrackingStatus.serviceDisabled);
    }
  }

  void _updateTrackingStatus(LocationTrackingStatus nextStatus) {
    _trackingStatus = nextStatus;
    _statusStreamController.add(nextStatus);
  }

  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: trackingDistanceFilterMeters,
        intervalDuration: const Duration(seconds: trackingIntervalSeconds),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Tadester Ops tracking',
          notificationText: 'Location tracking is active for assigned work.',
          enableWakeLock: false,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: trackingDistanceFilterMeters,
        pauseLocationUpdatesAutomatically: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: trackingDistanceFilterMeters,
    );
  }
}
