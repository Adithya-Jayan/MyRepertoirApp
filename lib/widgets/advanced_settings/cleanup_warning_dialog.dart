import 'package:flutter/material.dart';
import '../../services/media_cleanup_service.dart';

/// A dialog that warns the user before performing media cleanup.
class CleanupWarningDialog extends StatelessWidget {
  final MediaCleanupInfo cleanupInfo;
  final VoidCallback onConfirm;

  const CleanupWarningDialog({
    super.key,
    required this.cleanupInfo,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
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
          Text('Files to delete: ${cleanupInfo.unusedFilesFound}'),
          Text('Space to free: ${cleanupInfo.unusedSizeFormatted}'),
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
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete Files'),
        ),
      ],
    );
  }
} 