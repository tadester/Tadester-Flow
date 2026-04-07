import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../../shared/models/job.dart';
import '../../data/workspace_repository.dart';
import '../../domain/models/workspace_models.dart';
import '../providers/workspace_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({required this.workspace, super.key});

  final WorkspaceSummary workspace;

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final GlobalKey<FormState> _locationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _jobFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _assignmentFormKey = GlobalKey<FormState>();

  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController(
    text: 'Edmonton',
  );
  final TextEditingController _regionController = TextEditingController(
    text: 'AB',
  );
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(
    text: 'Canada',
  );
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: '120',
  );

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();

  bool _isCreatingLocation = false;
  bool _isCreatingJob = false;
  bool _isCreatingAssignment = false;
  String? _locationError;
  String? _jobError;
  String? _assignmentError;
  String? _selectedLocationId;
  String _selectedPriority = 'medium';
  String? _selectedJobId;
  String? _selectedWorkerId;
  DateTime _scheduledStartAt = DateTime.now().add(const Duration(hours: 2));
  DateTime _scheduledEndAt = DateTime.now().add(const Duration(hours: 4));

  @override
  void dispose() {
    _locationNameController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) {
      return;
    }
    context.goNamed(AppRoute.login.nameValue);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime current = isStart ? _scheduledStartAt : _scheduledEndAt;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final DateTime nextValue = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _scheduledStartAt = nextValue;
        if (!_scheduledEndAt.isAfter(_scheduledStartAt)) {
          _scheduledEndAt = _scheduledStartAt.add(const Duration(hours: 2));
        }
      } else {
        _scheduledEndAt = nextValue.isAfter(_scheduledStartAt)
            ? nextValue
            : _scheduledStartAt.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _submitLocation() async {
    if (!_locationFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingLocation = true;
      _locationError = null;
    });

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .createLocation(
            CreateLocationInput(
              name: _locationNameController.text.trim(),
              addressLine1: _addressLine1Controller.text.trim(),
              city: _cityController.text.trim(),
              region: _regionController.text.trim(),
              postalCode: _postalCodeController.text.trim(),
              country: _countryController.text.trim(),
              latitude: double.parse(_latitudeController.text.trim()),
              longitude: double.parse(_longitudeController.text.trim()),
              geofenceRadiusMeters: int.parse(_radiusController.text.trim()),
            ),
          );

      _locationNameController.clear();
      _addressLine1Controller.clear();
      _postalCodeController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _radiusController.text = '120';

      ref.invalidate(workspaceProvider);
      ref.invalidate(workspaceLocationsProvider);
    } catch (error) {
      setState(() {
        _locationError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingLocation = false;
        });
      }
    }
  }

  Future<void> _submitJob() async {
    if (!_jobFormKey.currentState!.validate() || _selectedLocationId == null) {
      setState(() {
        _jobError = 'Choose a location before creating a job.';
      });
      return;
    }

    setState(() {
      _isCreatingJob = true;
      _jobError = null;
    });

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .createJob(
            CreateJobInput(
              locationId: _selectedLocationId!,
              title: _jobTitleController.text.trim(),
              description: _jobDescriptionController.text.trim(),
              priority: _selectedPriority,
              scheduledStartAt: _scheduledStartAt,
              scheduledEndAt: _scheduledEndAt,
            ),
          );

      _jobTitleController.clear();
      _jobDescriptionController.clear();
      _selectedLocationId = null;
      _selectedPriority = 'medium';
      _scheduledStartAt = DateTime.now().add(const Duration(hours: 2));
      _scheduledEndAt = DateTime.now().add(const Duration(hours: 4));

      ref.invalidate(workspaceProvider);
      ref.invalidate(workspaceJobsProvider);
    } catch (error) {
      setState(() {
        _jobError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingJob = false;
        });
      }
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedJobId == null || _selectedWorkerId == null) {
      setState(() {
        _assignmentError = 'Choose both a job and a worker.';
      });
      return;
    }

    setState(() {
      _isCreatingAssignment = true;
      _assignmentError = null;
    });

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .createAssignment(
            CreateAssignmentInput(
              jobId: _selectedJobId!,
              workerProfileId: _selectedWorkerId!,
            ),
          );

      _selectedJobId = null;
      _selectedWorkerId = null;
      ref.invalidate(workspaceJobsProvider);
      ref.invalidate(employeesProvider);
    } catch (error) {
      setState(() {
        _assignmentError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAssignment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<EmployeeRecord>> employeesAsync = ref.watch(
      employeesProvider,
    );
    final AsyncValue<List<LocationRecord>> locationsAsync = ref.watch(
      workspaceLocationsProvider,
    );
    final AsyncValue<List<Job>> jobsAsync = ref.watch(workspaceJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.organization.name),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              ref.invalidate(workspaceProvider);
              ref.invalidate(employeesProvider);
              ref.invalidate(workspaceLocationsProvider);
              ref.invalidate(workspaceJobsProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dashboard',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workspaceProvider);
          ref.invalidate(employeesProvider);
          ref.invalidate(workspaceLocationsProvider);
          ref.invalidate(workspaceJobsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Admin workspace',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Signed in as ${widget.workspace.profile.fullName} (${widget.workspace.profile.role}).',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _MetricCard(
                  label: 'Employees',
                  value: widget.workspace.metrics.employeesCount.toString(),
                ),
                _MetricCard(
                  label: 'Field Workers',
                  value: widget.workspace.metrics.fieldWorkersCount.toString(),
                ),
                _MetricCard(
                  label: 'Locations',
                  value: widget.workspace.metrics.locationsCount.toString(),
                ),
                _MetricCard(
                  label: 'Active Jobs',
                  value: widget.workspace.metrics.activeJobsCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Employees',
              child: employeesAsync.when(
                data: (List<EmployeeRecord> employees) {
                  if (employees.isEmpty) {
                    return const Text(
                      'No employees found in this organization yet.',
                    );
                  }

                  return Column(
                    children: employees
                        .map(
                          (EmployeeRecord employee) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                employee.fullName.isNotEmpty
                                    ? employee.fullName.characters.first
                                          .toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(employee.fullName),
                            subtitle: Text(
                              '${employee.role} · ${employee.email}',
                            ),
                            trailing: _StatusChip(label: employee.status),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stackTrace) =>
                    Text(error.toString()),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Create location',
              child: Form(
                key: _locationFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _locationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Location name',
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressLine1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address line 1',
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                            ),
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _regionController,
                            decoration: const InputDecoration(
                              labelText: 'Region',
                            ),
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal code',
                            ),
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                            ),
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Geofence radius (meters)',
                      ),
                      validator: _integerValidator,
                    ),
                    if (_locationError != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _locationError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: _isCreatingLocation ? null : _submitLocation,
                        child: _isCreatingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Create job',
              child: Form(
                key: _jobFormKey,
                child: locationsAsync.when(
                  data: (List<LocationRecord> locations) {
                    return Column(
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLocationId,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                          items: locations
                              .map(
                                (LocationRecord location) =>
                                    DropdownMenuItem<String>(
                                      value: location.id,
                                      child: Text(location.name),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedLocationId = value;
                            });
                          },
                          validator: (String? value) =>
                              value == null ? 'Location is required.' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _jobTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Job title',
                          ),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _jobDescriptionController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem(
                              value: 'high',
                              child: Text('High'),
                            ),
                            DropdownMenuItem(
                              value: 'urgent',
                              child: Text('Urgent'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedPriority = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDateTime(isStart: true),
                                icon: const Icon(Icons.schedule),
                                label: Text(
                                  'Start: ${_formatDateTime(_scheduledStartAt)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDateTime(isStart: false),
                                icon: const Icon(Icons.event),
                                label: Text(
                                  'End: ${_formatDateTime(_scheduledEndAt)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_jobError != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _jobError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: _isCreatingJob ? null : _submitJob,
                            child: _isCreatingJob
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Create job'),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object error, StackTrace stackTrace) =>
                      Text(error.toString()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Assign a worker',
              child: Form(
                key: _assignmentFormKey,
                child: Column(
                  children: <Widget>[
                    jobsAsync.when(
                      data: (List<Job> jobs) => DropdownButtonFormField<String>(
                        initialValue: _selectedJobId,
                        decoration: const InputDecoration(labelText: 'Job'),
                        items: jobs
                            .map(
                              (Job job) => DropdownMenuItem<String>(
                                value: job.id,
                                child: Text(job.title),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedJobId = value;
                          });
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (Object error, StackTrace stackTrace) =>
                          Text(error.toString()),
                    ),
                    const SizedBox(height: 12),
                    employeesAsync.when(
                      data: (List<EmployeeRecord> employees) {
                        final List<EmployeeRecord> workers = employees
                            .where(
                              (EmployeeRecord employee) =>
                                  employee.role == 'field_worker',
                            )
                            .toList(growable: false);

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedWorkerId,
                          decoration: const InputDecoration(
                            labelText: 'Worker',
                          ),
                          items: workers
                              .map(
                                (EmployeeRecord worker) =>
                                    DropdownMenuItem<String>(
                                      value: worker.id,
                                      child: Text(worker.fullName),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedWorkerId = value;
                            });
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (Object error, StackTrace stackTrace) =>
                          Text(error.toString()),
                    ),
                    if (_assignmentError != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _assignmentError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: _isCreatingAssignment
                            ? null
                            : _submitAssignment,
                        child: _isCreatingAssignment
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Assign worker'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Current jobs',
              child: jobsAsync.when(
                data: (List<Job> jobs) {
                  if (jobs.isEmpty) {
                    return const Text(
                      'No jobs yet. Create one to get started.',
                    );
                  }

                  return Column(
                    children: jobs
                        .map(
                          (Job job) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(job.title),
                              subtitle: Text(
                                '${job.locationName} · ${_formatDateTime(job.scheduledAt)}',
                              ),
                              trailing: _StatusChip(label: job.status),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stackTrace) =>
                    Text(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (_requiredValidator(value) != null) {
      return _requiredValidator(value);
    }
    if (double.tryParse(value!.trim()) == null) {
      return 'Enter a valid number.';
    }
    return null;
  }

  String? _integerValidator(String? value) {
    if (_requiredValidator(value) != null) {
      return _requiredValidator(value);
    }
    if (int.tryParse(value!.trim()) == null) {
      return 'Enter a whole number.';
    }
    return null;
  }

  String _formatDateTime(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label.replaceAll('_', ' ')));
  }
}
