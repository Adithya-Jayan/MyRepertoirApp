import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../database/music_piece_repository.dart';
import '../services/media_cleanup_service.dart';
import '../widgets/advanced_settings/cleanup_warning_dialog.dart';
import '../widgets/advanced_settings/cleanup_details_dialog.dart';
import '../widgets/advanced_settings/scan_results_widget.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _debugLogsEnabled = false;
  bool _showPracticeTimeStats = false;
  bool _isScanning = false;
  bool _isCleaning = false;
  MediaCleanupInfo? _cleanupInfo;

  @override
  void initState() {
    super.initState();
    _debugLogsEnabled = AppLogger.debugLogsEnabled;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showPracticeTimeStats = prefs.getBool('show_practice_time_stats') ?? false;
    });
  }

  Future<void> _savePracticeTimeStatsSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_practice_time_stats', value);
    setState(() {
      _showPracticeTimeStats = value;
    });
  }

  Future<void> _scanForUnusedMedia() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final repository = MusicPieceRepository();
      final cleanupService = MediaCleanupService(repository);
      final info = await cleanupService.scanForUnusedMedia();
      
      setState(() {
        _cleanupInfo = info;
        _isScanning = false;
      });
    } catch (e) {
      AppLogger.log('Error scanning for unused media: $e');
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning for unused media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCleanupWarning() async {
    if (_cleanupInfo == null || _cleanupInfo!.unusedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unused files found to clean up.'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CleanupWarningDialog(
          cleanupInfo: _cleanupInfo!,
          onConfirm: _performCleanup,
        );
      },
    );

    if (confirmed == true) {
      await _performCleanup();
    }
  }

  Future<void> _performCleanup() async {
    setState(() {
      _isCleaning = true;
    });

    try {
      final repository = MusicPieceRepository();
      final cleanupService = MediaCleanupService(repository);
      final result = await cleanupService.performCleanup();
      
      setState(() {
        _isCleaning = false;
        _cleanupInfo = null; // Reset scan results
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () => _showCleanupDetails(result),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.log('Error performing cleanup: $e');
      setState(() {
        _isCleaning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing cleanup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCleanupDetails(MediaCleanupResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CleanupDetailsDialog(result: result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Debug Logs'),
            subtitle: const Text('Log detailed information for debugging'),
            value: _debugLogsEnabled,
            onChanged: (bool value) {
              setState(() {
                _debugLogsEnabled = value;
              });
              AppLogger.setDebugLogsEnabled(value);
            },
          ),
          SwitchListTile(
            title: const Text('Show Practice Time Statistics'),
            subtitle: const Text('Display duration and time-based statistics in practice logs'),
            value: _showPracticeTimeStats,
            onChanged: _savePracticeTimeStatsSetting,
          ),
          const Divider(),
          ListTile(
            title: const Text('Purge Unused Media'),
            subtitle: const Text('Remove media files that are no longer referenced'),
            leading: const Icon(Icons.cleaning_services),
            trailing: _isScanning || _isCleaning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios),
            onTap: _isScanning || _isCleaning ? null : _scanForUnusedMedia,
          ),
          if (_cleanupInfo != null)
            ScanResultsWidget(
              cleanupInfo: _cleanupInfo!,
              isCleaning: _isCleaning,
              onPurgeUnusedFiles: _showCleanupWarning,
            ),
        ],
      ),
    );
  }
}
