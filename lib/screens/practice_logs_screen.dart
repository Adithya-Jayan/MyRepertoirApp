import 'package:flutter/material.dart';

import '../models/music_piece.dart';
import '../models/practice_log.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';
import '../utils/practice_settings.dart';
import '../widgets/practice_logs/practice_summary_widget.dart';
import '../widgets/practice_logs/practice_log_tile.dart';
import '../widgets/practice_logs/practice_log_dialog.dart';

import 'package:repertoire/l10n/l10n.dart';

/// A screen that displays and manages practice logs for a specific music piece.
///
/// Allows users to view all practice sessions, add new ones, edit existing ones,
/// and delete practice sessions. Also provides a summary of practice statistics.
class PracticeLogsScreen extends StatefulWidget {
  final MusicPiece musicPiece;

  const PracticeLogsScreen({super.key, required this.musicPiece});

  @override
  State<PracticeLogsScreen> createState() => _PracticeLogsScreenState();
}

class _PracticeLogsScreenState extends State<PracticeLogsScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<PracticeLog> _practiceLogs = [];
  bool _isLoading = true;
  bool _showTimeStats = false;
  bool _showNotes = false;
  MusicPiece? _updatedMusicPiece;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPracticeLogs();
  }

  Future<void> _loadSettings() async {
    final showTimeStats = await PracticeSettings.getShowPracticeTimeStats();
    final showNotes = await PracticeSettings.getShowPracticeNotes();
    setState(() {
      _showTimeStats = showTimeStats;
      _showNotes = showNotes;
    });
  }

  Future<void> _loadPracticeLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _repository.getPracticeLogsForPiece(
        widget.musicPiece.id,
      );
      final updatedPiece = await _repository.getMusicPieceById(
        widget.musicPiece.id,
      );

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
      builder: (context) => PracticeLogDialog(
        showTimeStats: _showTimeStats,
        showNotes: _showNotes,
      ),
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
            SnackBar(
              content: Text(context.l10n.practiceSessionLoggedSuccessfully),
            ),
          );
        }
      } catch (e) {
        AppLogger.log('Error adding practice log: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.errorLoggingPracticeSession(e.toString()),
              ),
            ),
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
        showNotes: _showNotes,
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
            SnackBar(
              content: Text(context.l10n.practiceSessionUpdatedSuccessfully),
            ),
          );
        }
      } catch (e) {
        AppLogger.log('Error updating practice log: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.errorUpdatingPracticeSession(e.toString()),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePracticeLog(PracticeLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deletePracticeSession),
        content: Text(
          context.l10n.areYouSureYouWantToDeleteThisPracticeSessionThisAction,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
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
            SnackBar(
              content: Text(context.l10n.practiceSessionDeletedSuccessfully),
            ),
          );
        }
      } catch (e) {
        AppLogger.log('Error deleting practice log: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.errorDeletingPracticeSession(e.toString()),
              ),
            ),
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
        title: Text(context.l10n.practiceLogsForPiece(musicPiece.title)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPracticeLog,
            tooltip: context.l10n.addPracticeSession,
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
                      ? Center(
                          child: Text(
                            context
                                .l10n
                                .noPracticeSessionsRecordedYetTapThePlusButtonToAddYour,
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
                              showNotes: _showNotes,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
