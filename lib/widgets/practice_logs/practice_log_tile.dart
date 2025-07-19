import 'package:flutter/material.dart';
import '../../models/practice_log.dart';

/// A widget that displays a single practice log entry in a list tile.
class PracticeLogTile extends StatelessWidget {
  final PracticeLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showTimeStats;

  const PracticeLogTile({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
    required this.showTimeStats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.music_note),
        ),
        title: Text(log.formattedTimestamp),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTimeStats) Text(log.formattedDuration),
            if (log.notes != null && log.notes!.isNotEmpty)
              Text(
                log.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 