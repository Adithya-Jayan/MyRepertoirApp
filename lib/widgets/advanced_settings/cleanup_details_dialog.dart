import 'package:flutter/material.dart';
import '../../services/media_cleanup_service.dart';

/// A dialog that displays detailed cleanup results.
class CleanupDetailsDialog extends StatelessWidget {
  final MediaCleanupResult result;

  const CleanupDetailsDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
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
  }
} 