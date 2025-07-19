import 'package:flutter/material.dart';
import '../../services/media_cleanup_service.dart';

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
    return Padding(
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
              Text('Total files: ${cleanupInfo.totalFilesFound}'),
              Text('Total size: ${cleanupInfo.totalSizeFormatted}'),
              const Divider(),
              Text(
                'Unused files: ${cleanupInfo.unusedFilesFound}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Unused size: ${cleanupInfo.unusedSizeFormatted}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (cleanupInfo.unusedFiles.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCleaning ? null : onPurgeUnusedFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: isCleaning
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
    );
  }
} 