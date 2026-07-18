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

import 'package:repertoire/l10n/l10n.dart';

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
            content: Text(context.l10n.errorScanningUnusedMedia(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCleanupWarning() async {
    if (_cleanupInfo == null || _cleanupInfo!.unusedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noUnusedFilesFoundToCleanUp),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CleanupWarningDialog(cleanupInfo: _cleanupInfo!);
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
      final result = await cleanupService.performCleanup(
        cleanupInfo: _cleanupInfo,
        l10n: context.l10n,
      );

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
              label: context.l10n.details,
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
            content: Text(context.l10n.errorPerformingCleanup(e.toString())),
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
      appBar: AppBar(title: Text(context.l10n.advancedSettings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildCategoryHeader(
              theme,
              context.l10n.developerTools,
              Icons.bug_report_outlined,
            ),
            _buildSettingsCard([
              SwitchListTile(
                title: Text(context.l10n.enableDebugLogs),
                subtitle: Text(
                  context.l10n.captureTechnicalLogsForTroubleshooting,
                ),
                value: _debugLogsEnabled,
                onChanged: (bool value) async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final l10n = context.l10n;
                  if (!value) {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.l10n.deleteLogFile),
                        content: Text(
                          context.l10n.wouldYouLikeToDeleteTheExistingDebugLogs,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => navigator.pop(false),
                            child: Text(context.l10n.no),
                          ),
                          TextButton(
                            onPressed: () => navigator.pop(true),
                            child: Text(context.l10n.yesDelete),
                          ),
                        ],
                      ),
                    );
                    if (shouldDelete == true) {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final appStoragePath = prefs.getString(
                          'appStoragePath',
                        );
                        String? logFilePath;
                        if (appStoragePath != null &&
                            appStoragePath.isNotEmpty) {
                          logFilePath = p.join(
                            appStoragePath,
                            'logs',
                            'repertoir_logs.txt',
                          );
                        } else {
                          final directory =
                              await getApplicationDocumentsDirectory();
                          logFilePath = p.join(
                            directory.path,
                            'repertoir_logs.txt',
                          );
                        }
                        final logFile = io.File(logFilePath);
                        if (await logFile.exists()) {
                          await logFile.delete();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text(l10n.logFileDeleted)),
                          );
                        }
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.errorDeletingLogFile(e.toString()),
                            ),
                          ),
                        );
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
                          label: Text(context.l10n.openLogs),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            final navigator = Navigator.of(context);
                            final l10n = context.l10n;
                            final prefs = await SharedPreferences.getInstance();
                            final appStoragePath = prefs.getString(
                              'appStoragePath',
                            );
                            String? logFilePath;
                            if (appStoragePath != null &&
                                appStoragePath.isNotEmpty) {
                              logFilePath = p.join(
                                appStoragePath,
                                'logs',
                                'repertoir_logs.txt',
                              );
                            } else {
                              final directory =
                                  await getApplicationDocumentsDirectory();
                              logFilePath = p.join(
                                directory.path,
                                'repertoir_logs.txt',
                              );
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
                                  );
                                } else {
                                  throw Exception(
                                    'No app found to open the log file.',
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                showDialog(
                                  context: navigator.context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      context.l10n.couldNotOpenLogFile,
                                    ),
                                    content: Text(
                                      context
                                          .l10n
                                          .noAppWasFoundToOpenTheLogFileWouldYouLike,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => navigator.pop(),
                                        child: Text(context.l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          navigator.pop();
                                          await SharePlus.instance.share(
                                            ShareParams(
                                              files: [XFile(logFile.path)],
                                              text: context
                                                  .l10n
                                                  .repertoireAppDebugLog,
                                            ),
                                          );
                                        },
                                        child: Text(context.l10n.shareLogFile),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text(l10n.noLogFileFound)),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(context.l10n.deleteLogs),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            final navigator = Navigator.of(context);
                            final l10n = context.l10n;
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(context.l10n.deleteLogs2),
                                content: Text(
                                  context
                                      .l10n
                                      .areYouSureYouWantToDeleteTheDebugLogFile,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => navigator.pop(false),
                                    child: Text(context.l10n.no),
                                  ),
                                  TextButton(
                                    onPressed: () => navigator.pop(true),
                                    child: Text(
                                      context.l10n.delete,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final appStoragePath = prefs.getString(
                                  'appStoragePath',
                                );
                                String? logFilePath;
                                if (appStoragePath != null &&
                                    appStoragePath.isNotEmpty) {
                                  logFilePath = p.join(
                                    appStoragePath,
                                    'logs',
                                    'repertoir_logs.txt',
                                  );
                                } else {
                                  final directory =
                                      await getApplicationDocumentsDirectory();
                                  logFilePath = p.join(
                                    directory.path,
                                    'repertoir_logs.txt',
                                  );
                                }
                                final logFile = io.File(logFilePath);
                                if (await logFile.exists()) {
                                  await logFile.delete();
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text(l10n.logsDeleted)),
                                  );
                                }
                              } catch (e) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.errorDeletingLogs(e.toString()),
                                    ),
                                  ),
                                );
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
            _buildCategoryHeader(
              theme,
              context.l10n.dataManagement,
              Icons.folder_open_outlined,
            ),
            _buildSettingsCard([
              ListTile(
                title: Text(context.l10n.internalFileExplorer),
                subtitle: Text(context.l10n.browseAndManageInternalAppFiles),
                leading: const Icon(Icons.folder_shared_outlined),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InternalFileExplorerScreen(),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 16),
            _buildCategoryHeader(
              theme,
              context.l10n.cleanup,
              Icons.cleaning_services_outlined,
            ),
            _buildSettingsCard([
              ListTile(
                title: Text(context.l10n.purgeUnusedMedia),
                subtitle: Text(context.l10n.removeMediaFilesNoLongerReferenced),
                leading: const Icon(Icons.cleaning_services_outlined),
                trailing: _isScanning || _isCleaning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(children: children),
    );
  }
}
