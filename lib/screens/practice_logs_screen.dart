import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/music_piece.dart';
import '../models/practice_log.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';

/// A screen that displays and manages practice logs for a specific music piece.
///
/// Allows users to view all practice sessions, add new ones, edit existing ones,
/// and delete practice sessions. Also provides a summary of practice statistics.
class PracticeLogsScreen extends StatefulWidget {
  final MusicPiece musicPiece;

  const PracticeLogsScreen({
    super.key,
    required this.musicPiece,
  });

  @override
  State<PracticeLogsScreen> createState() => _PracticeLogsScreenState();
}

class _PracticeLogsScreenState extends State<PracticeLogsScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<PracticeLog> _practiceLogs = [];
  bool _isLoading = true;
  MusicPiece? _updatedMusicPiece;

  @override
  void initState() {
    super.initState();
    _loadPracticeLogs();
  }

  Future<void> _loadPracticeLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _repository.getPracticeLogsForPiece(widget.musicPiece.id);
      final updatedPiece = await _repository.getMusicPieceById(widget.musicPiece.id);
      
      setState(() {
        _practiceLogs = logs;
        _updatedMusicPiece = updatedPiece;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.log('Error loading practice logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addPracticeLog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PracticeLogDialog(),
    );

    if (result != null) {
      try {
        await _repository.logPracticeSession(
          widget.musicPiece.id,
          notes: result['notes'],
          durationMinutes: result['durationMinutes'],
        );
        await _loadPracticeLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Practice session logged successfully')),
          );
        }
      } catch (e) {
        AppLogger.log('Error adding practice log: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging practice session: $e')),
          );
        }
      }
    }
  }

  Future<void> _editPracticeLog(PracticeLog log) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PracticeLogDialog(
        initialNotes: log.notes,
        initialDurationMinutes: log.durationMinutes,
        initialTimestamp: log.timestamp,
      ),
    );

    if (result != null) {
      try {
        final updatedLog = log.copyWith(
          notes: result['notes'],
          durationMinutes: result['durationMinutes'],
          timestamp: result['timestamp'],
        );
        
        await _repository.updatePracticeLog(updatedLog);
        await _loadPracticeLogs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Practice session updated successfully')),
          );
        }
      } catch (e) {
        AppLogger.log('Error updating practice log: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating practice session: $e')),
          );
        }
      }
    }
  }

  Future<void> _deletePracticeLog(PracticeLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Practice Session'),
        content: const Text('Are you sure you want to delete this practice session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deletePracticeLog(log.id);
        await _loadPracticeLogs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Practice session deleted successfully')),
          );
        }
      } catch (e) {
        AppLogger.log('Error deleting practice log: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting practice session: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicPiece = _updatedMusicPiece ?? widget.musicPiece;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Logs - ${musicPiece.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPracticeLog,
            tooltip: 'Add Practice Session',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPracticeSummary(musicPiece),
                Expanded(
                  child: _practiceLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No practice sessions recorded yet.\nTap the + button to add your first practice session.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _practiceLogs.length,
                          itemBuilder: (context, index) {
                            final log = _practiceLogs[index];
                            return _PracticeLogTile(
                              log: log,
                              onEdit: () => _editPracticeLog(log),
                              onDelete: () => _deletePracticeLog(log),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPracticeSummary(MusicPiece musicPiece) {
    final totalDuration = _practiceLogs.fold<int>(
      0,
      (sum, log) => sum + log.durationMinutes,
    );
    
    final averageDuration = _practiceLogs.isNotEmpty 
        ? totalDuration / _practiceLogs.length 
        : 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Total Sessions',
                    value: '${musicPiece.practiceCount}',
                    icon: Icons.music_note,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Total Time',
                    value: _formatDuration(totalDuration),
                    icon: Icons.timer,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Average Time',
                    value: _formatDuration(averageDuration.round()),
                    icon: Icons.av_timer,
                  ),
                ),
              ],
            ),
            if (musicPiece.lastPracticeTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Last practiced: ${musicPiece.lastPracticeTime!.toLocal().toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }
}

/// A widget that displays a single practice log entry in a list tile.
class _PracticeLogTile extends StatelessWidget {
  final PracticeLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PracticeLogTile({
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.music_note),
        ),
        title: Text(log.formattedTimestamp),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.formattedDuration),
            if (log.notes != null && log.notes!.isNotEmpty)
              Text(
                log.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays a summary item with an icon, label, and value.
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A dialog for adding or editing practice logs.
class _PracticeLogDialog extends StatefulWidget {
  final String? initialNotes;
  final int? initialDurationMinutes;
  final DateTime? initialTimestamp;

  const _PracticeLogDialog({
    this.initialNotes,
    this.initialDurationMinutes,
    this.initialTimestamp,
  });

  @override
  State<_PracticeLogDialog> createState() => _PracticeLogDialogState();
}

class _PracticeLogDialogState extends State<_PracticeLogDialog> {
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
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
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