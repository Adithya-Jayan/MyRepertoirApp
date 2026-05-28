import 'package:flutter/material.dart';
import '../../services/media_cleanup_service.dart';
import './unused_files_dialog.dart';

/// A widget that displays media cleanup scan results.
class ScanResultsWidget extends StatelessWidget {
  final MediaCleanupInfo cleanupInfo;
  final bool isCleaning;
  final VoidCallback onPurgeUnusedFiles;

  const ScanResultsWidget({
    super.key,
    required this.cleanupInfo,
    required this.isCleaning,
    required this.onPurgeUnusedFiles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Scan Results',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildStatRow(theme, 'Total Files', '${cleanupInfo.totalFilesFound}', Icons.description_outlined),
              const SizedBox(height: 8),
              _buildStatRow(theme, 'Total Size', cleanupInfo.totalSizeFormatted, Icons.storage_outlined),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              
              _buildStatRow(
                theme, 
                'Unused Files', 
                '${cleanupInfo.unusedFilesFound}', 
                Icons.auto_delete_outlined,
                valueColor: cleanupInfo.unusedFilesFound > 0 ? colorScheme.error : null,
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                theme, 
                'Unused Size', 
                cleanupInfo.unusedSizeFormatted, 
                Icons.cleaning_services_outlined,
                valueColor: cleanupInfo.unusedFilesFound > 0 ? colorScheme.error : null,
                isBold: true,
              ),

              const SizedBox(height: 24),
              
              if (cleanupInfo.unusedFiles.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline, size: 18),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => UnusedFilesDialog(
                              unusedFiles: cleanupInfo.unusedFiles,
                            ),
                          );
                        },
                        label: const Text('View Unused Files'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: isCleaning 
                          ? const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_sweep_outlined, size: 18),
                        onPressed: isCleaning ? null : onPurgeUnusedFiles,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        label: Text(isCleaning ? 'Purging...' : 'Purge Unused Files'),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your media library is clean!',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value, IconData icon, {Color? valueColor, bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
 