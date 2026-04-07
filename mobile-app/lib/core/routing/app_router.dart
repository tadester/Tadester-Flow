import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/profile/presentation/screens/management/management_jobs_screen.dart';
import '../../features/profile/presentation/screens/management/management_overview_screen.dart';
import '../../features/profile/presentation/screens/management/management_settings_screen.dart';
import '../../features/profile/presentation/screens/management/management_workers_screen.dart';
import '../../features/profile/presentation/screens/worker/worker_jobs_screen.dart';
import '../../features/profile/presentation/screens/worker/worker_route_screen.dart';
import '../../features/profile/presentation/screens/worker/worker_settings_screen.dart';
import '../../features/profile/presentation/screens/workspace_screen.dart';
import '../../features/tracking/presentation/screens/location_permission_screen.dart';

enum AppRoute {
  splash('splash'),
  login('login'),
  signUp('sign-up'),
  workspace('workspace'),
  managerOverview('manager-overview'),
  managerJobs('manager-jobs'),
  managerWorkers('manager-workers'),
  managerSettings('manager-settings'),
  workerJobs('worker-jobs'),
  workerRoute('worker-route'),
  workerSettings('worker-settings'),
  jobDetail('job-detail'),
  permissions('permissions');

  const AppRoute(this.nameValue);

  final String nameValue;
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: AppRoute.splash.nameValue,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.nameValue,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoute.signUp.nameValue,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/workspace',
        name: AppRoute.workspace.nameValue,
        builder: (context, state) => const WorkspaceScreen(),
      ),
      GoRoute(
        path: '/manager/overview',
        name: AppRoute.managerOverview.nameValue,
        pageBuilder: (context, state) => _buildTabPage(
          state: state,
          child: const ManagementOverviewScreen(),
          currentIndex: 0,
        ),
      ),
      GoRoute(
        path: '/manager/jobs',
        name: AppRoute.managerJobs.nameValue,
        pageBuilder: (context, state) => _buildTabPage(
          state: state,
          child: const ManagementJobsScreen(),
          currentIndex: 1,
        ),
      ),
      GoRoute(
        path: '/manager/workers',
        name: AppRoute.managerWorkers.nameValue,
        pageBuilder: (context, state) => _buildTabPage(
          state: state,
          child: const ManagementWorkersScreen(),
          currentIndex: 2,
        ),
      ),
      GoRoute(
        path: '/manager/settings',
        name: AppRoute.managerSettings.nameValue,
        pageBuilder: (context, state) => _buildTabPage(
          state: state,
          child: const ManagementSettingsScreen(),
          currentIndex: 3,
        ),
      ),
      GoRoute(
        path: '/worker/jobs',
        name: AppRoute.workerJobs.nameValue,
        pageBuilder: (context, state) => _buildTabPage(
          state: state,
          child: const WorkerJobsScreen(),
          currentIndex: 0,
        ),
      ),
      GoRoute(
        path: '/worker/route',
        name: AppRoute.workerRoute.nameValue,
        pageBuilder: (context, state) => _buildTabPage(
          state: state,
          child: const WorkerRouteScreen(),
          currentIndex: 1,
        ),
      ),
      GoRoute(
        path: '/worker/settings',
        name: AppRoute.workerSettings.nameValue,
        pageBuilder: (context, state) => _buildTabPage(
          state: state,
          child: const WorkerSettingsScreen(),
          currentIndex: 2,
        ),
      ),
      GoRoute(
        path: '/jobs/:id',
        name: AppRoute.jobDetail.nameValue,
        builder: (context, state) =>
            JobDetailScreen(jobId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/permissions',
        name: AppRoute.permissions.nameValue,
        builder: (context, state) => const LocationPermissionScreen(),
      ),
    ],
    redirect: (context, state) => null,
  );
});

Page<void> _buildTabPage({
  required GoRouterState state,
  required Widget child,
  required int currentIndex,
}) {
  final int? previousIndex = state.extra is int ? state.extra as int : null;

  if (previousIndex == null || previousIndex == currentIndex) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  final Offset begin = currentIndex < previousIndex
      ? const Offset(-1, 0)
      : const Offset(1, 0);

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animatable<Offset> tween = Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
