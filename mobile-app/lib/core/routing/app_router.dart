import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/jobs/presentation/screens/jobs_list_screen.dart';
import '../../features/tracking/presentation/screens/location_permission_screen.dart';

enum AppRoute {
  splash('splash'),
  login('login'),
  jobs('jobs'),
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
        path: '/jobs',
        name: AppRoute.jobs.nameValue,
        builder: (context, state) => const JobsListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            name: AppRoute.jobDetail.nameValue,
            builder: (context, state) =>
                JobDetailScreen(jobId: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
      GoRoute(
        path: '/permissions',
        name: AppRoute.permissions.nameValue,
        builder: (context, state) => const LocationPermissionScreen(),
      ),
    ],
    // Hook reserved for future auth-based redirect logic.
    redirect: (context, state) => null,
  );
});
