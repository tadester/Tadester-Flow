import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/workspace_models.dart';
import '../../providers/workspace_providers.dart';
import '../../widgets/management_shell.dart';

class ManagementWorkersScreen extends ConsumerWidget {
  const ManagementWorkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return workspaceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Workers')),
        body: Center(
          child: Text(
            'Unable to load workspace.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (workspace) => ManagementShell(
        workspace: workspace,
        currentTab: ManagementTab.workers,
        pageTitle: 'Workers',
        onRefresh: () {
          ref.invalidate(workspaceProvider);
          ref.invalidate(employeesProvider);
        },
        body: employeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Text(
              'Unable to load employees.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
          data: (employees) {
            final workers = employees
                .where((employee) => employee.isWorker)
                .toList(growable: false);
            final managers = employees
                .where((employee) => !employee.isWorker)
                .toList(growable: false);

            return ListView(
              children: <Widget>[
                _Section(title: 'Field workers', employees: workers),
                const SizedBox(height: 20),
                _Section(title: 'Management team', employees: managers),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.employees});

  final String title;
  final List<EmployeeRecord> employees;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (employees.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No employees found.'),
            ),
          )
        else
          ...employees.map(
            (employee) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(employee.fullName),
                subtitle: Text(
                  '${employee.email} · ${employee.role.replaceAll('_', ' ')}',
                ),
                trailing: Chip(label: Text(employee.status)),
              ),
            ),
          ),
      ],
    );
  }
}
