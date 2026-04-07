import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/workspace_repository.dart';
import '../../providers/workspace_providers.dart';
import '../../widgets/management_shell.dart';

class ManagementJobsScreen extends ConsumerStatefulWidget {
  const ManagementJobsScreen({super.key});

  @override
  ConsumerState<ManagementJobsScreen> createState() =>
      _ManagementJobsScreenState();
}

class _ManagementJobsScreenState extends ConsumerState<ManagementJobsScreen> {
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

  String? _selectedLocationId;
  String _selectedPriority = 'medium';
  DateTime _scheduledStartAt = DateTime.now().add(const Duration(hours: 2));
  DateTime _scheduledEndAt = DateTime.now().add(const Duration(hours: 4));
  String? _selectedJobId;
  String? _selectedWorkerId;
  bool _isBusy = false;

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

  Future<void> _refreshAll() async {
    ref.invalidate(workspaceProvider);
    ref.invalidate(workspaceJobsProvider);
    ref.invalidate(workspaceLocationsProvider);
    ref.invalidate(employeesProvider);
  }

  Future<void> _showDateTimePicker({required bool isStart}) async {
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

    final nextValue = DateTime(
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

  Future<void> _createLocation() async {
    if (!_locationFormKey.currentState!.validate()) {
      return;
    }

    await _runBusyAction(() async {
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
      await _refreshAll();
      _showMessage('Location created.');
    });
  }

  Future<void> _createJob() async {
    if (!_jobFormKey.currentState!.validate() || _selectedLocationId == null) {
      _showMessage('Choose a location and complete the job form.');
      return;
    }

    await _runBusyAction(() async {
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
      setState(() {
        _selectedLocationId = null;
        _selectedPriority = 'medium';
      });
      await _refreshAll();
      _showMessage('Job created.');
    });
  }

  Future<void> _assignManually() async {
    if (_selectedJobId == null || _selectedWorkerId == null) {
      _showMessage('Choose both a job and a worker.');
      return;
    }

    await _runBusyAction(() async {
      await ref
          .read(workspaceRepositoryProvider)
          .createAssignment(
            CreateAssignmentInput(
              jobId: _selectedJobId!,
              workerProfileId: _selectedWorkerId!,
            ),
          );
      setState(() {
        _selectedJobId = null;
        _selectedWorkerId = null;
      });
      await _refreshAll();
      _showMessage('Job assigned manually.');
    });
  }

  Future<void> _autoAssign({String? jobId}) async {
    await _runBusyAction(() async {
      final result = await ref
          .read(workspaceRepositoryProvider)
          .autoAssignJobs(jobId: jobId);
      await _refreshAll();
      _showMessage(
        'Auto-assigned ${result.assignmentsCreated.length} job(s). '
        '${result.skippedJobs.length} skipped.',
      );
    });
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final workspaceAsync = ref.watch(workspaceProvider);
    final jobsAsync = ref.watch(workspaceJobsProvider);
    final locationsAsync = ref.watch(workspaceLocationsProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return workspaceAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Jobs')),
        body: Center(
          child: Text(
            'Unable to load workspace.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (workspace) => ManagementShell(
        workspace: workspace,
        currentTab: ManagementTab.jobs,
        pageTitle: 'Jobs',
        onRefresh: _refreshAll,
        body: ListView(
          children: <Widget>[
            if (_isBusy) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBusy ? null : () => _autoAssign(),
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Auto-assign open jobs'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _locationFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Create location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationNameController,
                        decoration: const InputDecoration(
                          labelText: 'Location name',
                        ),
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _addressLine1Controller,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _regionController,
                        decoration: const InputDecoration(labelText: 'Region'),
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _postalCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Postal code',
                        ),
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(labelText: 'Country'),
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredValidator,
                      ),
                      TextFormField(
                        controller: _radiusController,
                        decoration: const InputDecoration(
                          labelText: 'Geofence radius (m)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isBusy ? null : _createLocation,
                        child: const Text('Save location'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            locationsAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (Object error, StackTrace stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Unable to load locations.\n$error'),
                ),
              ),
              data: (locations) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _jobFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Create job',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLocationId,
                          items: locations
                              .map(
                                (location) => DropdownMenuItem<String>(
                                  value: location.id,
                                  child: Text(location.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) =>
                              setState(() => _selectedLocationId = value),
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                        ),
                        TextFormField(
                          controller: _jobTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Job title',
                          ),
                          validator: _requiredValidator,
                        ),
                        TextFormField(
                          controller: _jobDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          validator: _requiredValidator,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPriority,
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
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedPriority = value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: _isBusy
                                  ? null
                                  : () => _showDateTimePicker(isStart: true),
                              child: Text(
                                'Start: ${_formatDateTime(_scheduledStartAt)}',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _isBusy
                                  ? null
                                  : () => _showDateTimePicker(isStart: false),
                              child: Text(
                                'End: ${_formatDateTime(_scheduledEndAt)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isBusy ? null : _createJob,
                          child: const Text('Create job'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            employeesAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (Object error, StackTrace stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Unable to load workers.\n$error'),
                ),
              ),
              data: (employees) {
                final workers = employees
                    .where((employee) => employee.isWorker)
                    .toList(growable: false);
                return jobsAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (Object error, StackTrace stackTrace) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Unable to load jobs.\n$error'),
                    ),
                  ),
                  data: (jobs) => Column(
                    children: <Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _assignmentFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Manual assignment',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedJobId,
                                  items: jobs
                                      .map(
                                        (job) => DropdownMenuItem<String>(
                                          value: job.id,
                                          child: Text(job.title),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) =>
                                      setState(() => _selectedJobId = value),
                                  decoration: const InputDecoration(
                                    labelText: 'Job',
                                  ),
                                ),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedWorkerId,
                                  items: workers
                                      .map(
                                        (worker) => DropdownMenuItem<String>(
                                          value: worker.id,
                                          child: Text(worker.fullName),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) =>
                                      setState(() => _selectedWorkerId = value),
                                  decoration: const InputDecoration(
                                    labelText: 'Worker',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _isBusy ? null : _assignManually,
                                  child: const Text('Assign worker'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...jobs.map(
                        (job) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  job.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${job.locationName} · ${_formatDateTime(job.scheduledStartAt)}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Priority: ${job.priority} · Status: ${job.status.replaceAll('_', ' ')}',
                                ),
                                if (job.description != null &&
                                    job.description!.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Text(job.description!),
                                ],
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: _isBusy
                                        ? null
                                        : () => _autoAssign(jobId: job.id),
                                    icon: const Icon(Icons.auto_fix_high),
                                    label: const Text('Auto-assign this job'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  static String _formatDateTime(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
