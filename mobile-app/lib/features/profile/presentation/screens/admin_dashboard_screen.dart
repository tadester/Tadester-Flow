import 'package:flutter/material.dart';

import '../../domain/models/workspace_models.dart';
import 'management/management_overview_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({required this.workspace, super.key});

  final WorkspaceSummary workspace;

  @override
  Widget build(BuildContext context) {
    return const ManagementOverviewScreen();
  }
}
