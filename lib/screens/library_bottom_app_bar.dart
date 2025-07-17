import 'package:flutter/material.dart';

class LibraryBottomAppBar extends StatelessWidget {
  final bool isMultiSelectMode;
  final VoidCallback onDeleteSelectedPieces;
  final VoidCallback onModifyGroupOfSelectedPieces;
  final bool isSelectionEmpty;

  const LibraryBottomAppBar({
    super.key,
    required this.isMultiSelectMode,
    required this.onDeleteSelectedPieces,
    required this.onModifyGroupOfSelectedPieces,
    required this.isSelectionEmpty,
  });

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.group_work),
            label: const Text('Modify Group'),
            onPressed: isSelectionEmpty ? null : onModifyGroupOfSelectedPieces,
          ),
        ],
      ),
    );
  }
}
