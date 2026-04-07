import '../../../core/services/backend_api_client.dart';
import '../domain/models/location_data.dart';

class TrackingRepository {
  TrackingRepository({required BackendApiClient apiClient})
    : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<void> sendPing(LocationData location) async {
    await _apiClient.postJson(
      '/api/tracking/ping',
      body: <String, dynamic>{
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'timestamp': location.timestamp.toIso8601String(),
      },
    );
  }
}
