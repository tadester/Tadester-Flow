class WorkspaceOrganization {
  const WorkspaceOrganization({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
  });

  final String id;
  final String name;
  final String slug;
  final String status;

  factory WorkspaceOrganization.fromJson(Map<String, dynamic> json) {
    return WorkspaceOrganization(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown organization',
      slug: json['slug'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class WorkspaceProfile {
  const WorkspaceProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String status;

  bool get isManagementRole => role != 'field_worker';

  factory WorkspaceProfile.fromJson(Map<String, dynamic> json) {
    return WorkspaceProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown user',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'field_worker',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class WorkspaceMetrics {
  const WorkspaceMetrics({
    required this.employeesCount,
    required this.fieldWorkersCount,
    required this.locationsCount,
    required this.jobsCount,
    required this.activeJobsCount,
  });

  final int employeesCount;
  final int fieldWorkersCount;
  final int locationsCount;
  final int jobsCount;
  final int activeJobsCount;

  factory WorkspaceMetrics.fromJson(Map<String, dynamic> json) {
    return WorkspaceMetrics(
      employeesCount: json['employees_count'] as int? ?? 0,
      fieldWorkersCount: json['field_workers_count'] as int? ?? 0,
      locationsCount: json['locations_count'] as int? ?? 0,
      jobsCount: json['jobs_count'] as int? ?? 0,
      activeJobsCount: json['active_jobs_count'] as int? ?? 0,
    );
  }
}

class WorkspaceSummary {
  const WorkspaceSummary({
    required this.organization,
    required this.profile,
    required this.metrics,
  });

  final WorkspaceOrganization organization;
  final WorkspaceProfile profile;
  final WorkspaceMetrics metrics;

  factory WorkspaceSummary.fromJson(Map<String, dynamic> json) {
    return WorkspaceSummary(
      organization: WorkspaceOrganization.fromJson(
        json['organization'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      profile: WorkspaceProfile.fromJson(
        json['profile'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      metrics: WorkspaceMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class EmployeeRecord {
  const EmployeeRecord({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String status;

  bool get isWorker => role == 'field_worker';

  factory EmployeeRecord.fromJson(Map<String, dynamic> json) {
    return EmployeeRecord(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown employee',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'field_worker',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class LocationRecord {
  const LocationRecord({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
  });

  final String id;
  final String name;
  final String city;
  final String region;
  final String status;
  final double latitude;
  final double longitude;
  final int geofenceRadiusMeters;

  factory LocationRecord.fromJson(Map<String, dynamic> json) {
    return LocationRecord(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown location',
      city: json['city'] as String? ?? '',
      region: json['region'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      geofenceRadiusMeters: json['geofence_radius_meters'] as int? ?? 0,
    );
  }
}

class WorkspaceJobRecord {
  const WorkspaceJobRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
  });

  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String locationId;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;

  factory WorkspaceJobRecord.fromJson(Map<String, dynamic> json) {
    return WorkspaceJobRecord(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled job',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      priority: json['priority'] as String? ?? 'medium',
      locationId: json['location_id'] as String? ?? '',
      locationName: json['location_name'] as String? ?? 'Unknown location',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      scheduledStartAt: DateTime.parse(json['scheduled_start_at'] as String),
      scheduledEndAt: DateTime.parse(json['scheduled_end_at'] as String),
    );
  }
}

class RouteLegSummary {
  const RouteLegSummary({
    required this.fromJobId,
    required this.toJobId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.estimatedArrival,
  });

  final String? fromJobId;
  final String toJobId;
  final int distanceMeters;
  final int durationSeconds;
  final DateTime estimatedArrival;

  factory RouteLegSummary.fromJson(Map<String, dynamic> json) {
    return RouteLegSummary(
      fromJobId: json['from_job_id'] as String?,
      toJobId: json['to_job_id'] as String? ?? '',
      distanceMeters: json['distance_meters'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      estimatedArrival: DateTime.parse(
        json['estimated_arrival'] as String? ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}

class WorkerRouteStop {
  const WorkerRouteStop({
    required this.id,
    required this.title,
    required this.status,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
  });

  final String id;
  final String title;
  final String status;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;

  factory WorkerRouteStop.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> location =
        json['location'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return WorkerRouteStop(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled stop',
      status: json['status'] as String? ?? 'scheduled',
      locationName: location['name'] as String? ?? 'Unknown location',
      latitude: (location['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0,
      scheduledAt: DateTime.parse(json['scheduled_start_at'] as String),
    );
  }
}

class WorkerRouteSummary {
  const WorkerRouteSummary({
    required this.orderedJobs,
    required this.legs,
    required this.totalDistance,
    required this.totalTime,
  });

  final List<WorkerRouteStop> orderedJobs;
  final List<RouteLegSummary> legs;
  final int totalDistance;
  final int totalTime;

  WorkerRouteStop? get nextStop =>
      orderedJobs.isEmpty ? null : orderedJobs.first;

  factory WorkerRouteSummary.fromJson(Map<String, dynamic> json) {
    final List<WorkerRouteStop> orderedJobs =
        ((json['ordered_jobs'] as List?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(WorkerRouteStop.fromJson)
            .toList(growable: false);

    final List<RouteLegSummary> legs = ((json['legs'] as List?) ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(RouteLegSummary.fromJson)
        .toList(growable: false);

    return WorkerRouteSummary(
      orderedJobs: orderedJobs,
      legs: legs,
      totalDistance: json['total_distance'] as int? ?? 0,
      totalTime: json['total_time'] as int? ?? 0,
    );
  }
}

class AutoAssignRunResult {
  const AutoAssignRunResult({
    required this.assignmentsCreated,
    required this.skippedJobs,
  });

  final List<AutoAssignedJob> assignmentsCreated;
  final List<AutoAssignSkippedJob> skippedJobs;

  factory AutoAssignRunResult.fromJson(Map<String, dynamic> json) {
    return AutoAssignRunResult(
      assignmentsCreated:
          ((json['assignments_created'] as List?) ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(AutoAssignedJob.fromJson)
              .toList(growable: false),
      skippedJobs: ((json['skipped_jobs'] as List?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AutoAssignSkippedJob.fromJson)
          .toList(growable: false),
    );
  }
}

class AutoAssignedJob {
  const AutoAssignedJob({
    required this.jobId,
    required this.workerProfileId,
    required this.workerName,
    required this.distanceMeters,
  });

  final String jobId;
  final String workerProfileId;
  final String workerName;
  final int distanceMeters;

  factory AutoAssignedJob.fromJson(Map<String, dynamic> json) {
    return AutoAssignedJob(
      jobId: json['job_id'] as String,
      workerProfileId: json['worker_profile_id'] as String,
      workerName: json['worker_name'] as String? ?? 'Assigned worker',
      distanceMeters: json['distance_meters'] as int? ?? 0,
    );
  }
}

class AutoAssignSkippedJob {
  const AutoAssignSkippedJob({required this.jobId, required this.reason});

  final String jobId;
  final String reason;

  factory AutoAssignSkippedJob.fromJson(Map<String, dynamic> json) {
    return AutoAssignSkippedJob(
      jobId: json['job_id'] as String,
      reason: json['reason'] as String? ?? 'Unknown reason',
    );
  }
}
