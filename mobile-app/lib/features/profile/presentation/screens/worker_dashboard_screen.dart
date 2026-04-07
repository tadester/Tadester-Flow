import 'package:flutter/material.dart';

import '../../domain/models/workspace_models.dart';
import 'worker/worker_jobs_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({required this.workspace, super.key});

  final WorkspaceSummary workspace;

  @override
  Widget build(BuildContext context) {
    return const WorkerJobsScreen();
  }
}
