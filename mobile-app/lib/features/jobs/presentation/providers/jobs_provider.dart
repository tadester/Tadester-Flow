import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/backend_api_client.dart';
import '../../../../shared/models/job.dart';
import '../../data/jobs_repository.dart';

final Provider<JobsRepository> jobsRepositoryProvider =
    Provider<JobsRepository>((Ref ref) {
      return JobsRepository(apiClient: ref.read(backendApiClientProvider));
    });

final FutureProvider<List<Job>> jobsProvider = FutureProvider<List<Job>>((
  Ref ref,
) {
  return ref.read(jobsRepositoryProvider).getAssignedJobs();
});
