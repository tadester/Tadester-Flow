class Job {
  const Job({
    required this.id,
    required this.title,
    required this.status,
    required this.locationName,
    required this.scheduledAt,
  });

  final String id;
  final String title;
  final String status;
  final String locationName;
  final DateTime scheduledAt;

  factory Job.fromBackendJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled job',
      status: json['status'] as String? ?? 'scheduled',
      locationName:
          json['location_name'] as String? ??
          json['locationName'] as String? ??
          'Unknown location',
      scheduledAt: DateTime.parse(json['scheduled_start_at'] as String),
    );
  }
}
