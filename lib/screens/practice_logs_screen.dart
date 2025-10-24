import 'package:flutter/material.dart';

import '../models/music_piece.dart';
import '../models/practice_log.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';
import '../utils/practice_settings.dart';
import '../widgets/practice_logs/practice_summary_widget.dart';
import '../widgets/practice_logs/practice_log_tile.dart';
import '../widgets/practice_logs/practice_log_dialog.dart';

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
  bool _showTimeStats = false;
  MusicPiece? _updatedMusicPiece;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPracticeLogs();
  }

  Future<void> _loadSettings() async {
    final showTimeStats = await PracticeSettings.getShowPracticeTimeStats();
    setState(() {
      _showTimeStats = showTimeStats;
    });
  }

  Future<void> _loadPracticeLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _repository.getPracticeLogsForPiece(widget.musicPiece.id);
      final updatedPiece = await _repository.getMusicPieceById(widget.musicPiece.id);
      
      // Sort logs by most recent first
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
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
      builder: (context) => PracticeLogDialog(showTimeStats: _showTimeStats),
    );

    if (result != null) {
      try {
        await _repository.logPracticeSession(
          widget.musicPiece.id,
          notes: result['notes'],
          durationMinutes: result['durationMinutes'],
          timestamp: result['timestamp'],
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
      builder: (context) => PracticeLogDialog(
        initialNotes: log.notes,
        initialDurationMinutes: log.durationMinutes,
        initialTimestamp: log.timestamp,
        showTimeStats: _showTimeStats,
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
                PracticeSummaryWidget(
                  musicPiece: musicPiece,
                  practiceLogs: _practiceLogs,
                  showTimeStats: _showTimeStats,
                ),
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
                            return PracticeLogTile(
                              log: log,
                              onEdit: () => _editPracticeLog(log),
                              onDelete: () => _deletePracticeLog(log),
                              showTimeStats: _showTimeStats,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

 