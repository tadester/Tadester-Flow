import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/backend_api_client.dart';
import '../../../../shared/models/job.dart';
import '../../data/workspace_repository.dart';
import '../../domain/models/workspace_models.dart';

final Provider<WorkspaceRepository> workspaceRepositoryProvider =
    Provider<WorkspaceRepository>((Ref ref) {
      return WorkspaceRepository(apiClient: ref.read(backendApiClientProvider));
    });

final FutureProvider<WorkspaceSummary> workspaceProvider =
    FutureProvider<WorkspaceSummary>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getWorkspace();
    });

final FutureProvider<List<EmployeeRecord>> employeesProvider =
    FutureProvider<List<EmployeeRecord>>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getEmployees();
    });

final FutureProvider<List<LocationRecord>> workspaceLocationsProvider =
    FutureProvider<List<LocationRecord>>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getLocations();
    });

final FutureProvider<List<Job>> workspaceJobsProvider =
    FutureProvider<List<Job>>((Ref ref) {
      return ref.read(workspaceRepositoryProvider).getJobs();
    });

final FutureProvider<WorkerRouteSummary> workerRouteProvider =
    FutureProvider<WorkerRouteSummary>((Ref ref) {
      return ref
          .read(workspaceRepositoryProvider)
          .getMyRoute(date: _todayIsoDate());
    });

String _todayIsoDate() {
  final DateTime now = DateTime.now();
  final String year = now.year.toString().padLeft(4, '0');
  final String month = now.month.toString().padLeft(2, '0');
  final String day = now.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
