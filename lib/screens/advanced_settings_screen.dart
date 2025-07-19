import 'package:flutter/material.dart';
import '../utils/app_logger.dart';
import '../database/music_piece_repository.dart';
import '../services/media_cleanup_service.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _debugLogsEnabled = false;
  bool _isScanning = false;
  bool _isCleaning = false;
  MediaCleanupInfo? _cleanupInfo;

  @override
  void initState() {
    super.initState();
    _debugLogsEnabled = AppLogger.debugLogsEnabled;
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
        return AlertDialog(
          title: const Text('Purge Unused Media'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete unused media files that are no longer referenced by any music pieces.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Files to delete: ${_cleanupInfo!.unusedFilesFound}'),
              Text('Space to free: ${_cleanupInfo!.unusedSizeFormatted}'),
              const SizedBox(height: 16),
              const Text(
                '⚠️ This action cannot be undone. Make sure you have a backup before proceeding.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Files'),
            ),
          ],
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
        return AlertDialog(
          title: const Text('Cleanup Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Files deleted: ${result.filesDeleted}'),
              Text('Space freed: ${result.freedSizeFormatted}'),
              Text('Status: ${result.success ? 'Success' : 'Partial Success'}'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.map((error) => Text('• $error')),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
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
          if (_cleanupInfo != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Total files: ${_cleanupInfo!.totalFilesFound}'),
                      Text('Total size: ${_cleanupInfo!.totalSizeFormatted}'),
                      const Divider(),
                      Text(
                        'Unused files: ${_cleanupInfo!.unusedFilesFound}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Unused size: ${_cleanupInfo!.unusedSizeFormatted}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_cleanupInfo!.unusedFiles.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCleaning ? null : _showCleanupWarning,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: _isCleaning
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Cleaning...'),
                                    ],
                                  )
                                : const Text('Purge Unused Files'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
