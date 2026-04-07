import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/models/job.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/jobs_provider.dart';

class JobsListScreen extends ConsumerStatefulWidget {
  const JobsListScreen({super.key});

  @override
  ConsumerState<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends ConsumerState<JobsListScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await ref.read(authRepositoryProvider).signOut();

      if (!mounted) {
        return;
      }

      context.goNamed(AppRoute.login.nameValue);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Job>> jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Jobs'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Location permissions',
            onPressed: () => context.goNamed(AppRoute.permissions.nameValue),
            icon: const Icon(Icons.my_location_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) => Center(
              child: Text(
                'Unable to load jobs.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
            data: (List<Job> jobs) {
              if (jobs.isEmpty) {
                return const Center(child: Text('No assigned jobs'));
              }

              return ListView.separated(
                itemCount: jobs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Job job = jobs[index];

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(job.title),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(job.locationName),
                            const SizedBox(height: 4),
                            Text(DateTimeFormatter.format(job.scheduledAt)),
                          ],
                        ),
                      ),
                      trailing: _StatusBadge(status: job.status),
                      onTap: () => context.goNamed(
                        AppRoute.jobDetail.nameValue,
                        pathParameters: <String, String>{'id': job.id},
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = status == 'in_progress' || status == 'scheduled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.primaryColor.withValues(alpha: 0.12)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: highlighted ? AppTheme.primaryColor : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
