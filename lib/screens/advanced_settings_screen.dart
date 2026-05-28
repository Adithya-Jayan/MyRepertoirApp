import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../database/music_piece_repository.dart';
import '../services/media_cleanup_service.dart';
import '../widgets/advanced_settings/cleanup_warning_dialog.dart';
import '../widgets/advanced_settings/cleanup_details_dialog.dart';
import '../widgets/advanced_settings/scan_results_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'internal_file_explorer_screen.dart';

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
        return CleanupWarningDialog(
          cleanupInfo: _cleanupInfo!,
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
      final result = await cleanupService.performCleanup(cleanupInfo: _cleanupInfo);
      
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildCategoryHeader(theme, 'Developer Tools', Icons.bug_report_outlined),
            _buildSettingsCard([
              SwitchListTile(
                title: const Text('Enable Debug Logs'),
                subtitle: const Text('Capture technical logs for troubleshooting'),
                value: _debugLogsEnabled,
                onChanged: (bool value) async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  if (!value) {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Log File?'),
                        content: const Text('Would you like to delete the existing debug logs?'),
                        actions: [
                          TextButton(onPressed: () => navigator.pop(false), child: const Text('No')),
                          TextButton(onPressed: () => navigator.pop(true), child: const Text('Yes, delete')),
                        ],
                      ),
                    );
                    if (shouldDelete == true) {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final appStoragePath = prefs.getString('appStoragePath');
                        String? logFilePath;
                        if (appStoragePath != null && appStoragePath.isNotEmpty) {
                          logFilePath = p.join(appStoragePath, 'logs', 'repertoir_logs.txt');
                        } else {
                          final directory = await getApplicationDocumentsDirectory();
                          logFilePath = p.join(directory.path, 'repertoir_logs.txt');
                        }
                        final logFile = io.File(logFilePath);
                        if (await logFile.exists()) {
                          await logFile.delete();
                          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Log file deleted.')));
                        }
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting log file: $e')));
                      }
                    }
                  }
                  if (mounted) setState(() => _debugLogsEnabled = value);
                  AppLogger.setDebugLogsEnabled(value);
                },
              ),
              if (_debugLogsEnabled)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Open Logs'),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final prefs = await SharedPreferences.getInstance();
                            final appStoragePath = prefs.getString('appStoragePath');
                            String? logFilePath;
                            if (appStoragePath != null && appStoragePath.isNotEmpty) {
                              logFilePath = p.join(appStoragePath, 'logs', 'repertoir_logs.txt');
                            } else {
                              final directory = await getApplicationDocumentsDirectory();
                              logFilePath = p.join(directory.path, 'repertoir_logs.txt');
                            }
                            final logFile = io.File(logFilePath);
                            if (await logFile.exists()) {
                              try {
                                final uri = Uri.file(logFile.path);
                                final canLaunch = await canLaunchUrl(uri);
                                if (canLaunch) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  throw Exception('No app found to open the log file.');
                                }
                              } catch (e) {
                                if (!mounted) return;
                                showDialog(
                                  context: navigator.context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Could not open log file'),
                                    content: const Text('No app was found to open the log file. Would you like to share it instead?'),
                                    actions: [
                                      TextButton(onPressed: () => navigator.pop(), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () async {
                                          navigator.pop();
                                          await SharePlus.instance.share(ShareParams(
                                            files: [XFile(logFile.path)],
                                            text: 'Repertoire app debug log',
                                          ));
                                        },
                                        child: const Text('Share Log File'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              scaffoldMessenger.showSnackBar(const SnackBar(content: Text('No log file found.')));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete Logs'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Logs?'),
                                content: const Text('Are you sure you want to delete the debug log file?'),
                                actions: [
                                  TextButton(onPressed: () => navigator.pop(false), child: const Text('No')),
                                  TextButton(onPressed: () => navigator.pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final appStoragePath = prefs.getString('appStoragePath');
                                String? logFilePath;
                                if (appStoragePath != null && appStoragePath.isNotEmpty) {
                                  logFilePath = p.join(appStoragePath, 'logs', 'repertoir_logs.txt');
                                } else {
                                  final directory = await getApplicationDocumentsDirectory();
                                  logFilePath = p.join(directory.path, 'repertoir_logs.txt');
                                }
                                final logFile = io.File(logFilePath);
                                if (await logFile.exists()) {
                                  await logFile.delete();
                                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Logs deleted.')));
                                }
                              } catch (e) {
                                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting logs: $e')));
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ]),

            const SizedBox(height: 16),
            _buildCategoryHeader(theme, 'Data Management', Icons.folder_open_outlined),
            _buildSettingsCard([
              ListTile(
                title: const Text('Internal File Explorer'),
                subtitle: const Text('Browse and manage internal app files'),
                leading: const Icon(Icons.folder_shared_outlined),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InternalFileExplorerScreen()));
                },
              ),
            ]),

            const SizedBox(height: 16),
            _buildCategoryHeader(theme, 'Cleanup', Icons.cleaning_services_outlined),
            _buildSettingsCard([
              ListTile(
                title: const Text('Purge Unused Media'),
                subtitle: const Text('Remove media files no longer referenced'),
                leading: const Icon(Icons.cleaning_services_outlined),
                trailing: _isScanning || _isCleaning
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right, size: 18),
                onTap: _isScanning || _isCleaning ? null : _scanForUnusedMedia,
              ),
              if (_cleanupInfo != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ScanResultsWidget(
                    cleanupInfo: _cleanupInfo!,
                    isCleaning: _isCleaning,
                    onPurgeUnusedFiles: _showCleanupWarning,
                  ),
                ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(children: children),
    );
  }
}
