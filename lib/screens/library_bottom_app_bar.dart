import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class LibraryBottomAppBar extends StatelessWidget {
  final bool isMultiSelectMode;
  final VoidCallback onDeleteSelectedPieces;
  final VoidCallback onModifyGroupOfSelectedPieces;
  final VoidCallback onDuplicateSelectedPiece;
  final bool isSelectionEmpty;
  final int selectedCount;

  const LibraryBottomAppBar({
    super.key,
    required this.isMultiSelectMode,
    required this.onDeleteSelectedPieces,
    required this.onModifyGroupOfSelectedPieces,
    required this.onDuplicateSelectedPiece,
    required this.isSelectionEmpty,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.log('LibraryBottomAppBar: build called');
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            onPressed: isSelectionEmpty ? null : onDeleteSelectedPieces,
          ),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Duplicate'),
            onPressed: selectedCount == 1 ? onDuplicateSelectedPiece : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.group_work),
            label: const Text('Modify Group'),
            onPressed: isSelectionEmpty ? null : onModifyGroupOfSelectedPieces,
          ),
        ],
      ),
    );
  }
}
