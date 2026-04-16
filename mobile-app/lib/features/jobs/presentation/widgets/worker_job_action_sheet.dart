import 'package:flutter/material.dart';

class WorkerJobActionRequest {
  const WorkerJobActionRequest({
    required this.action,
    this.notes,
    this.reason,
  });

  final String action;
  final String? notes;
  final String? reason;
}

Future<WorkerJobActionRequest?> showWorkerJobActionSheet(
  BuildContext context, {
  required String jobTitle,
}) {
  return showModalBottomSheet<WorkerJobActionRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _WorkerJobActionSheet(jobTitle: jobTitle),
  );
}

class _WorkerJobActionSheet extends StatefulWidget {
  const _WorkerJobActionSheet({required this.jobTitle});

  final String jobTitle;

  @override
  State<_WorkerJobActionSheet> createState() => _WorkerJobActionSheetState();
}

class _WorkerJobActionSheetState extends State<_WorkerJobActionSheet> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _selectedAction = 'complete';
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 16 + viewInsets.bottom),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Close out ${widget.jobTitle}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how this stop ended, capture any notes, and Tadester Ops will move you to the next stop automatically.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'complete',
                    label: Text('Finished'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment<String>(
                    value: 'unable',
                    label: Text('Could not do it'),
                    icon: Icon(Icons.report_gmailerrorred_outlined),
                  ),
                ],
                selected: <String>{_selectedAction},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedAction = selection.first;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes for dispatch or admin',
                  hintText: 'Access details, photos taken, extra cleanup, etc.',
                ),
              ),
              if (_selectedAction == 'unable') ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason this job could not be completed',
                    hintText: 'Required',
                  ),
                ),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Confirm & next stop'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final String? notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final String? reason = _reasonController.text.trim().isEmpty
        ? null
        : _reasonController.text.trim();

    if (_selectedAction == 'unable' && reason == null) {
      setState(() {
        _errorMessage = 'Tell the team why this stop could not be completed.';
      });
      return;
    }

    Navigator.of(context).pop(
      WorkerJobActionRequest(
        action: _selectedAction,
        notes: notes,
        reason: reason,
      ),
    );
  }
}
