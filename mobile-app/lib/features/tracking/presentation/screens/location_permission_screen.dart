import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/location_data.dart';
import '../providers/location_service_provider.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen> {
  LocationPermissionState? _permissionState;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPermissionState();
    });
  }

  Future<void> _refreshPermissionState() async {
    try {
      final LocationService service = ref.read(locationServiceProvider);
      final LocationPermissionState permissionState = await service
          .getPermissionState();

      if (!mounted) {
        return;
      }

      setState(() {
        _permissionState = permissionState;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to read location permission state right now.';
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final LocationService service = ref.read(locationServiceProvider);
      final LocationPermissionState permissionState = await service
          .requestPermission();

      if (!mounted) {
        return;
      }

      setState(() {
        _permissionState = permissionState;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to request location permission right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _startTracking() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final LocationService service = ref.read(locationServiceProvider);
      await service.startTracking();
      await service.prepareBackgroundTrackingHook();
      await ref.read(trackingSyncServiceProvider).start();
      final LocationPermissionState permissionState = await service
          .getPermissionState();

      if (!mounted) {
        return;
      }

      setState(() {
        _permissionState = permissionState;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to start tracking right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _stopTracking() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await ref.read(trackingSyncServiceProvider).stop();
      await ref.read(locationServiceProvider).stopTracking();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to stop tracking right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await ref.read(locationServiceProvider).openAppSettings();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to open app settings right now.';
      });
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      await ref.read(locationServiceProvider).openLocationSettings();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to open location settings right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<LocationTrackingStatus> trackingStatusAsync = ref.watch(
      locationTrackingStatusProvider,
    );
    final AsyncValue<LocationData> latestLocationAsync = ref.watch(
      locationUpdatesProvider,
    );
    final LocationPermissionState permissionState =
        _permissionState ?? LocationPermissionState.denied;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('Location Access'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Keep crews visible without burning battery.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Tadester Ops only tracks location while you are actively '
                'working assigned jobs. Before the system permission prompt, '
                'we explain what is collected and why.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _InfoPanel(
                title: _panelTitle(permissionState),
                message: _panelMessage(permissionState),
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _TrackingStatusCard(
                trackingStatusAsync: trackingStatusAsync,
                latestLocationAsync: latestLocationAsync,
              ),
              const SizedBox(height: 12),
              if (defaultTargetPlatform == TargetPlatform.iOS)
                Card(
                  color: const Color(0xFFFFF8E1),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'On iPhone, Open app settings takes you to the Tadester Ops settings page. Apple does not allow apps to jump straight into the Location sub-page, so tap Location there to finish enabling tracking.',
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _buildActions(permissionState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(LocationPermissionState permissionState) {
    final List<Widget> actions = <Widget>[];

    if (permissionState == LocationPermissionState.denied) {
      actions.add(
        FilledButton(
          onPressed: _isBusy ? null : _requestPermission,
          child: _ButtonLabel(
            isBusy: _isBusy,
            label: 'Continue to system prompt',
          ),
        ),
      );
    }

    if (permissionState == LocationPermissionState.deniedForever) {
      actions.add(
        FilledButton(
          onPressed: _isBusy ? null : _openAppSettings,
          child: const Text('Open app settings'),
        ),
      );
    }

    if (permissionState == LocationPermissionState.serviceDisabled) {
      actions.add(
        FilledButton(
          onPressed: _isBusy ? null : _openLocationSettings,
          child: const Text('Turn on location services'),
        ),
      );
    }

    if (permissionState == LocationPermissionState.granted) {
      actions.add(
        FilledButton(
          onPressed: _isBusy ? null : _startTracking,
          child: _ButtonLabel(isBusy: _isBusy, label: 'Start tracking'),
        ),
      );
      actions.add(
        OutlinedButton(
          onPressed: _isBusy ? null : _stopTracking,
          child: const Text('Stop tracking'),
        ),
      );
    }

    actions.add(
      TextButton(
        onPressed: _isBusy ? null : _refreshPermissionState,
        child: const Text('Refresh status'),
      ),
    );

    return actions;
  }

  String _panelTitle(LocationPermissionState permissionState) {
    switch (permissionState) {
      case LocationPermissionState.granted:
        return 'Location access is ready';
      case LocationPermissionState.denied:
        return 'Allow location while working';
      case LocationPermissionState.deniedForever:
        return 'Location access was blocked';
      case LocationPermissionState.serviceDisabled:
        return 'Turn on device location services';
    }
  }

  String _panelMessage(LocationPermissionState permissionState) {
    switch (permissionState) {
      case LocationPermissionState.granted:
        return 'Foreground tracking can run roughly every 60 seconds with '
            'high accuracy and a modest distance filter to stay battery '
            'conscious.';
      case LocationPermissionState.denied:
        return 'We use location to record worker pings, keep dispatch current, '
            'and prepare for geofence-based job activity. Tap continue only '
            'when you are ready to see the OS permission dialog.';
      case LocationPermissionState.deniedForever:
        return 'The app cannot request location again until you change it in '
            'system settings. Open settings to re-enable access.';
      case LocationPermissionState.serviceDisabled:
        return 'GPS or device-level location services are off. Turn them on '
            'before the app can begin tracking.';
    }
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}

class _TrackingStatusCard extends StatelessWidget {
  const _TrackingStatusCard({
    required this.trackingStatusAsync,
    required this.latestLocationAsync,
  });

  final AsyncValue<LocationTrackingStatus> trackingStatusAsync;
  final AsyncValue<LocationData> latestLocationAsync;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = trackingStatusAsync.maybeWhen(
      data: (LocationTrackingStatus status) => switch (status) {
        LocationTrackingStatus.idle => 'Idle',
        LocationTrackingStatus.tracking => 'Tracking',
        LocationTrackingStatus.permissionDenied => 'Permission denied',
        LocationTrackingStatus.permissionDeniedForever =>
          'Permission denied forever',
        LocationTrackingStatus.serviceDisabled => 'Location services disabled',
        LocationTrackingStatus.stopped => 'Stopped',
      },
      orElse: () => 'Waiting for tracker',
    );

    final String locationLabel = latestLocationAsync.maybeWhen(
      data: (LocationData value) =>
          'Latest fix: ${value.latitude.toStringAsFixed(5)}, '
          '${value.longitude.toStringAsFixed(5)} · '
          '${value.accuracy.toStringAsFixed(0)}m',
      orElse: () => 'No location fix received yet.',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tracking status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(statusLabel),
          const SizedBox(height: 8),
          Text(locationLabel),
        ],
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.isBusy, required this.label});

  final bool isBusy;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!isBusy) {
      return Text(label);
    }

    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
