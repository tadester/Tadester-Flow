import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

class RouteCoordinate {
  const RouteCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String get asQueryValue => '$latitude,$longitude';
}

class RouteDirectionsData {
  const RouteDirectionsData({
    required this.polylinePoints,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  final List<RouteCoordinate> polylinePoints;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
}

class GoogleDirectionsService {
  GoogleDirectionsService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _httpClient;

  Future<RouteDirectionsData?> buildRoute({
    required RouteCoordinate origin,
    required List<RouteCoordinate> stops,
  }) async {
    if (!Env.hasGoogleMapsKey || stops.isEmpty) {
      return null;
    }

    final RouteCoordinate destination = stops.last;
    final List<RouteCoordinate> waypointStops = stops.length > 1
        ? stops.sublist(0, stops.length - 1)
        : const <RouteCoordinate>[];

    final Map<String, String> queryParameters = <String, String>{
      'origin': origin.asQueryValue,
      'destination': destination.asQueryValue,
      'mode': 'driving',
      'key': Env.googleMapsApiKey!,
    };

    if (waypointStops.isNotEmpty) {
      queryParameters['waypoints'] = waypointStops
          .map((RouteCoordinate stop) => stop.asQueryValue)
          .join('|');
    }

    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      queryParameters,
    );

    final http.Response response = await _httpClient
        .get(uri)
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Directions request failed with ${response.statusCode}.');
    }

    final dynamic payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Directions response was not a JSON object.');
    }

    final String status = payload['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      throw Exception('Directions request failed: $status');
    }

    final List<dynamic> routes = payload['routes'] as List<dynamic>? ?? <dynamic>[];
    if (routes.isEmpty) {
      return null;
    }

    final Map<String, dynamic> route = routes.first as Map<String, dynamic>;
    final Map<String, dynamic> polyline =
        route['overview_polyline'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final String encodedPoints = polyline['points'] as String? ?? '';
    final List<dynamic> legs = route['legs'] as List<dynamic>? ?? <dynamic>[];

    int totalDistanceMeters = 0;
    int totalDurationSeconds = 0;

    for (final dynamic leg in legs.whereType<Map<String, dynamic>>()) {
      totalDistanceMeters += (leg['distance'] as Map<String, dynamic>? ?? const <String, dynamic>{})['value'] as int? ?? 0;
      totalDurationSeconds += (leg['duration'] as Map<String, dynamic>? ?? const <String, dynamic>{})['value'] as int? ?? 0;
    }

    return RouteDirectionsData(
      polylinePoints: _decodePolyline(encodedPoints),
      totalDistanceMeters: totalDistanceMeters,
      totalDurationSeconds: totalDurationSeconds,
    );
  }

  List<RouteCoordinate> _decodePolyline(String encoded) {
    if (encoded.isEmpty) {
      return const <RouteCoordinate>[];
    }

    final List<RouteCoordinate> points = <RouteCoordinate>[];
    int index = 0;
    int latitude = 0;
    int longitude = 0;

    while (index < encoded.length) {
      final _PolylineChunk latitudeChunk = _decodeChunk(encoded, index);
      index = latitudeChunk.nextIndex;
      latitude += latitudeChunk.value;

      final _PolylineChunk longitudeChunk = _decodeChunk(encoded, index);
      index = longitudeChunk.nextIndex;
      longitude += longitudeChunk.value;

      points.add(
        RouteCoordinate(
          latitude: latitude / 1e5,
          longitude: longitude / 1e5,
        ),
      );
    }

    return points;
  }

  _PolylineChunk _decodeChunk(String encoded, int startIndex) {
    int index = startIndex;
    int result = 0;
    int shift = 0;
    int byte = 0;

    do {
      byte = encoded.codeUnitAt(index) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      index += 1;
    } while (byte >= 0x20 && index < encoded.length);

    final int delta = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    return _PolylineChunk(value: delta, nextIndex: index);
  }
}

class _PolylineChunk {
  const _PolylineChunk({required this.value, required this.nextIndex});

  final int value;
  final int nextIndex;
}
