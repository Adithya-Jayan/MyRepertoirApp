import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:repertoire/l10n/l10n.dart';

/// A dialog for adding or editing practice logs.
class PracticeLogDialog extends StatefulWidget {
  final String? initialNotes;
  final int? initialDurationMinutes;
  final DateTime? initialTimestamp;
  final bool showTimeStats;
  final bool showNotes;

  const PracticeLogDialog({
    super.key,
    this.initialNotes,
    this.initialDurationMinutes,
    this.initialTimestamp,
    required this.showTimeStats,
    required this.showNotes,
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

      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTimestamp != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? context.l10n.editPracticeSession
            : context.l10n.addPracticeSession,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(context.l10n.dateAndTime),
              subtitle: Text(
                DateFormat.yMd(
                  context.l10n.localeName,
                ).add_jm().format(_selectedDateTime),
              ),
              onTap: _selectDateTime,
            ),
            if (widget.showTimeStats) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: context.l10n.durationMinutesLabel,
                  hintText: context.l10n.eG30,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (widget.showNotes) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: context.l10n.notesOptional,
                  hintText:
                      context.l10n.eGWorkedOnDynamicsFocusedOnDifficultPassages,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final durationMinutes = int.tryParse(_durationController.text) ?? 0;
            Navigator.of(context).pop({
              'timestamp': _selectedDateTime,
              'durationMinutes': durationMinutes,
              'notes': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            });
          },
          child: Text(isEditing ? context.l10n.update : context.l10n.add),
        ),
      ],
    );
  }
}
