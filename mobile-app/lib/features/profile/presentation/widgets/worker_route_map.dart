import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../tracking/domain/models/location_data.dart';
import '../../domain/models/workspace_models.dart';

class WorkerRouteMap extends StatefulWidget {
  const WorkerRouteMap({
    super.key,
    required this.route,
    required this.currentLocation,
  });

  final WorkerRouteSummary route;
  final LocationData? currentLocation;

  @override
  State<WorkerRouteMap> createState() => _WorkerRouteMapState();
}

class _WorkerRouteMapState extends State<WorkerRouteMap> {
  GoogleMapController? _mapController;
  bool _hasFittedInitialBounds = false;

  @override
  void didUpdateWidget(covariant WorkerRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool locationChanged =
        oldWidget.currentLocation?.timestamp !=
        widget.currentLocation?.timestamp;
    final bool stopCountChanged =
        oldWidget.route.orderedJobs.length != widget.route.orderedJobs.length;

    if (_mapController == null) {
      return;
    }

    if (!_hasFittedInitialBounds || stopCountChanged) {
      unawaited(_fitToRoute());
      return;
    }

    if (locationChanged && widget.currentLocation != null) {
      unawaited(
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(
              widget.currentLocation!.latitude,
              widget.currentLocation!.longitude,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 320,
        child: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialTarget,
                zoom: 12,
              ),
              myLocationEnabled: widget.currentLocation != null,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                unawaited(_fitToRoute());
              },
              markers: _markers,
              polylines: _polylines,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'worker-route-recenter',
                onPressed: _fitToRoute,
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng get _initialTarget {
    if (widget.currentLocation != null) {
      return LatLng(
        widget.currentLocation!.latitude,
        widget.currentLocation!.longitude,
      );
    }

    if (widget.route.orderedJobs.isNotEmpty) {
      final WorkerRouteStop stop = widget.route.orderedJobs.first;
      return LatLng(stop.latitude, stop.longitude);
    }

    return const LatLng(53.5461, -113.4938);
  }

  Set<Marker> get _markers {
    final Set<Marker> markers = <Marker>{};

    if (widget.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('worker-current-location'),
          position: LatLng(
            widget.currentLocation!.latitude,
            widget.currentLocation!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your live location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    for (int index = 0; index < widget.route.orderedJobs.length; index += 1) {
      final WorkerRouteStop stop = widget.route.orderedJobs[index];
      markers.add(
        Marker(
          markerId: MarkerId('job-stop-${stop.id}'),
          position: LatLng(stop.latitude, stop.longitude),
          infoWindow: InfoWindow(
            title: '${index + 1}. ${stop.title}',
            snippet: stop.locationName,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            index == 0 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    final List<LatLng> points = <LatLng>[
      if (widget.currentLocation != null)
        LatLng(
          widget.currentLocation!.latitude,
          widget.currentLocation!.longitude,
        ),
      ...widget.route.orderedJobs.map(
        (WorkerRouteStop stop) => LatLng(stop.latitude, stop.longitude),
      ),
    ];

    if (points.length < 2) {
      return <Polyline>{};
    }

    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('worker-route-line'),
        width: 5,
        color: const Color(0xFFE53935),
        points: points,
      ),
    };
  }

  Future<void> _fitToRoute() async {
    final GoogleMapController? controller = _mapController;
    if (controller == null) {
      return;
    }

    final List<LatLng> points = <LatLng>[
      if (widget.currentLocation != null)
        LatLng(
          widget.currentLocation!.latitude,
          widget.currentLocation!.longitude,
        ),
      ...widget.route.orderedJobs.map(
        (WorkerRouteStop stop) => LatLng(stop.latitude, stop.longitude),
      ),
    ];

    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 14),
        ),
      );
      _hasFittedInitialBounds = true;
      return;
    }

    final double minLat = points
        .map((point) => point.latitude)
        .reduce((a, b) => a < b ? a : b);
    final double maxLat = points
        .map((point) => point.latitude)
        .reduce((a, b) => a > b ? a : b);
    final double minLng = points
        .map((point) => point.longitude)
        .reduce((a, b) => a < b ? a : b);
    final double maxLng = points
        .map((point) => point.longitude)
        .reduce((a, b) => a > b ? a : b);

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        56,
      ),
    );
    _hasFittedInitialBounds = true;
  }
}
