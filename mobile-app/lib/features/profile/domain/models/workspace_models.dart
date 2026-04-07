import '../../../../shared/models/job.dart';

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

class WorkerRouteSummary {
  const WorkerRouteSummary({
    required this.orderedJobs,
    required this.legs,
    required this.totalDistance,
    required this.totalTime,
  });

  final List<Job> orderedJobs;
  final List<RouteLegSummary> legs;
  final int totalDistance;
  final int totalTime;

  factory WorkerRouteSummary.fromJson(Map<String, dynamic> json) {
    final List<Job> orderedJobs =
        ((json['ordered_jobs'] as List?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> item) {
              final Map<String, dynamic> location =
                  item['location'] as Map<String, dynamic>? ??
                  <String, dynamic>{};

              return Job.fromBackendJson(<String, dynamic>{
                'id': item['id'],
                'title': item['title'],
                'status': item['status'],
                'location_name': location['name'],
                'scheduled_start_at': item['scheduled_start_at'],
              });
            })
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
