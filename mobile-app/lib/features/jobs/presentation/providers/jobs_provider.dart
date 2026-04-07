import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/job.dart';
import '../../data/jobs_repository.dart';

final Provider<JobsRepository> jobsRepositoryProvider =
    Provider<JobsRepository>((Ref ref) {
      return JobsRepository();
    });

final FutureProvider<List<Job>> jobsProvider = FutureProvider<List<Job>>((
  Ref ref,
) {
  return ref.read(jobsRepositoryProvider).getAssignedJobs();
});
