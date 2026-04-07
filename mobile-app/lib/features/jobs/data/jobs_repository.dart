import '../../../core/services/backend_api_client.dart';
import '../../../shared/models/job.dart';

class JobsRepository {
  JobsRepository({required BackendApiClient apiClient}) : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<List<Job>> getAssignedJobs() async {
    final Map<String, dynamic> response = await _apiClient.getJson('/api/jobs');
    final dynamic data = response['data'];

    if (data is! List) {
      return <Job>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Job.fromBackendJson)
        .toList(growable: false);
  }
}
