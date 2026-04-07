import '../../../shared/models/job.dart';

class JobsRepository {
  Future<List<Job>> getAssignedJobs() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return <Job>[
      Job(
        id: 'job-001',
        title: 'North Yard Snow Clearing',
        status: 'scheduled',
        locationName: 'North Yard Depot',
        scheduledAt: DateTime.parse('2026-04-07T08:00:00.000'),
      ),
      Job(
        id: 'job-002',
        title: 'Riverbend Walkway Salting',
        status: 'in_progress',
        locationName: 'Riverbend Commercial Lot',
        scheduledAt: DateTime.parse('2026-04-07T10:30:00.000'),
      ),
      Job(
        id: 'job-003',
        title: 'Fence Line Inspection',
        status: 'scheduled',
        locationName: 'West Service Corridor',
        scheduledAt: DateTime.parse('2026-04-07T13:15:00.000'),
      ),
      Job(
        id: 'job-004',
        title: 'Equipment Pickup',
        status: 'completed',
        locationName: 'South Yard Depot',
        scheduledAt: DateTime.parse('2026-04-07T15:00:00.000'),
      ),
    ];
  }
}
