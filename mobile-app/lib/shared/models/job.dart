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
}
