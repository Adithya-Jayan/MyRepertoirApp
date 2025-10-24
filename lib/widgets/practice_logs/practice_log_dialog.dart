import 'package:flutter/material.dart';

/// A dialog for adding or editing practice logs.
class PracticeLogDialog extends StatefulWidget {
  final String? initialNotes;
  final int? initialDurationMinutes;
  final DateTime? initialTimestamp;
  final bool showTimeStats;

  const PracticeLogDialog({
    super.key,
    this.initialNotes,
    this.initialDurationMinutes,
    this.initialTimestamp,
    required this.showTimeStats,
  });

  @override
  State<PracticeLogDialog> createState() => _PracticeLogDialogState();
}

class _PracticeLogDialogState extends State<PracticeLogDialog> {
  late TextEditingController _notesController;
  late TextEditingController _durationController;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _durationController = TextEditingController(
      text: widget.initialDurationMinutes?.toString() ?? '',
    );
    _selectedDateTime = widget.initialTimestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final navigator = Navigator.of(context);
    final date = await showDatePicker(
      context: navigator.context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      if (mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            _selectedDateTime.hour,
            _selectedDateTime.minute,
          );
        });
      }

      final time = await showTimePicker(
        context: navigator.context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            _selectedDateTime.year,
            _selectedDateTime.month,
            _selectedDateTime.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTimestamp != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit Practice Session' : 'Add Practice Session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Date & Time'),
              subtitle: Text(_selectedDateTime.toString().split('.')[0]),
              onTap: _selectDateTime,
            ),
            if (widget.showTimeStats) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  hintText: 'e.g., 30',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Worked on dynamics, focused on difficult passages',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final durationMinutes = int.tryParse(_durationController.text) ?? 0;
            Navigator.of(context).pop({
              'timestamp': _selectedDateTime,
              'durationMinutes': durationMinutes,
              'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            });
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
} 