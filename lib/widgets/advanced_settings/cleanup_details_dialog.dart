import 'package:flutter/material.dart';
import '../../services/media_cleanup_service.dart';

/// A dialog that displays detailed cleanup results with Material 3 styling.
class CleanupDetailsDialog extends StatelessWidget {
  final MediaCleanupResult result;

  const CleanupDetailsDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: result.success ? Colors.green : colorScheme.error,
          ),
          const SizedBox(width: 12),
          const Text('Cleanup Summary'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow(theme, 'Files Deleted', '${result.filesDeleted}', Icons.delete_outline),
            _buildResultRow(theme, 'Space Freed', result.freedSizeFormatted, Icons.auto_delete_outlined),
            _buildResultRow(
              theme, 
              'Status', 
              result.success ? 'Success' : 'Partial Success', 
              result.success ? Icons.done_all : Icons.priority_high,
              valueColor: result.success ? Colors.green : colorScheme.error,
            ),
            
            if (result.errors.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Errors encountered:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.errors.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              result.errors[index],
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildResultRow(ThemeData theme, String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
