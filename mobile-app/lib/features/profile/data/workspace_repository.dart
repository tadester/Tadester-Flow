import '../../../core/services/backend_api_client.dart';
import '../domain/models/workspace_models.dart';

class CreateLocationInput {
  const CreateLocationInput({
    required this.name,
    required this.addressLine1,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    this.addressLine2,
  });

  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String region;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final int geofenceRadiusMeters;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'region': region,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'status': 'active',
    };
  }
}

class CreateJobInput {
  const CreateJobInput({
    required this.locationId,
    required this.title,
    required this.description,
    required this.priority,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
  });

  final String locationId;
  final String title;
  final String description;
  final String priority;
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'locationId': locationId,
      'title': title,
      'description': description,
      'status': 'scheduled',
      'priority': priority,
      'scheduledStartAt': scheduledStartAt.toUtc().toIso8601String(),
      'scheduledEndAt': scheduledEndAt.toUtc().toIso8601String(),
    };
  }
}

class CreateAssignmentInput {
  const CreateAssignmentInput({
    required this.jobId,
    required this.workerProfileId,
  });

  final String jobId;
  final String workerProfileId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'jobId': jobId,
      'workerProfileId': workerProfileId,
      'assignmentStatus': 'assigned',
    };
  }
}

class WorkspaceRepository {
  const WorkspaceRepository({required BackendApiClient apiClient})
    : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<WorkspaceSummary> getWorkspace() async {
    final Map<String, dynamic> response = await _apiClient.getJson(
      '/api/organizations/me/workspace',
    );
    return WorkspaceSummary.fromJson(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<List<EmployeeRecord>> getEmployees() async {
    final Map<String, dynamic> response = await _apiClient.getJson(
      '/api/employees',
    );
    final dynamic data = response['data'];

    if (data is! List) {
      return <EmployeeRecord>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(EmployeeRecord.fromJson)
        .toList(growable: false);
  }

  Future<List<LocationRecord>> getLocations() async {
    final Map<String, dynamic> response = await _apiClient.getJson(
      '/api/locations',
    );
    final dynamic data = response['data'];

    if (data is! List) {
      return <LocationRecord>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(LocationRecord.fromJson)
        .toList(growable: false);
  }

  Future<List<WorkspaceJobRecord>> getJobs() async {
    final Map<String, dynamic> response = await _apiClient.getJson('/api/jobs');
    final dynamic data = response['data'];

    if (data is! List) {
      return <WorkspaceJobRecord>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(WorkspaceJobRecord.fromJson)
        .toList(growable: false);
  }

  Future<WorkerRouteSummary> getMyRoute({required String date}) async {
    final Map<String, dynamic> response = await _apiClient.getJson(
      '/api/workers/me/route?date=$date',
    );
    return WorkerRouteSummary.fromJson(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<void> createLocation(CreateLocationInput input) async {
    await _apiClient.postJson('/api/locations', body: input.toJson());
  }

  Future<void> createJob(CreateJobInput input) async {
    await _apiClient.postJson('/api/jobs', body: input.toJson());
  }

  Future<void> createAssignment(CreateAssignmentInput input) async {
    await _apiClient.postJson('/api/assignments', body: input.toJson());
  }

  Future<WorkspaceJobRecord> runWorkerJobAction({
    required String jobId,
    required String action,
    String? notes,
    String? reason,
  }) async {
    final Map<String, dynamic> response = await _apiClient.postJson(
      '/api/jobs/$jobId/worker-action',
      body: <String, dynamic>{
        'action': action,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    return WorkspaceJobRecord.fromJson(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<AutoAssignRunResult> autoAssignJobs({String? jobId}) async {
    final Map<String, dynamic> response = await _apiClient.postJson(
      '/api/assignments/auto',
      body: jobId == null
          ? const <String, dynamic>{}
          : <String, dynamic>{'jobId': jobId},
    );

    return AutoAssignRunResult.fromJson(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }
}
