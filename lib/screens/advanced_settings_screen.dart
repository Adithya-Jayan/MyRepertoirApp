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
            onChanged: (bool value) async {
              if (!value) {
                // If disabling, ask if user wants to delete the log file
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Log File?'),
                    content: const Text('Would you like to delete the debug log file created so far?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes, delete'),
                      ),
                    ],
                  ),
                );
                if (shouldDelete == true) {
                  // Delete the log file
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
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Log file deleted.')),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No log file found to delete.')),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting log file: $e')),
                      );
                    }
                  }
                }
              }
              setState(() {
                _debugLogsEnabled = value;
              });
              AppLogger.setDebugLogsEnabled(value);
            },
          ),
          if (_debugLogsEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open Log File'),
                      onPressed: () async {
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
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                                webViewConfiguration: const WebViewConfiguration(),
                                // Provide a mime type hint for text files
                                // (This is supported on Android/iOS, ignored on web/desktop)
                                // See: https://pub.dev/documentation/url_launcher/latest/url_launcher/launchUrl.html
                                // For best compatibility, use LaunchMode.externalApplication
                              );
                            } else {
                              throw Exception('No app found to open the log file.');
                            }
                          } catch (e) {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Could not open log file'),
                                  content: const Text('No app was found to open the log file. You may need to install a text editor app.\n\nWould you like to share the log file instead?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await Share.shareXFiles([XFile(logFile.path)], text: 'Repertoire app debug log');
                                      },
                                      child: const Text('Share Log File'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No log file found to open.')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Log File'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Log File?'),
                            content: const Text('Are you sure you want to delete the debug log file?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Yes, delete'),
                              ),
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
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Log file deleted.')),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No log file found to delete.')),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting log file: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
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
