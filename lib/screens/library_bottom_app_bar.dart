import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

import 'package:repertoire/l10n/l10n.dart';

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
            label: Text(context.l10n.delete),
            onPressed: isSelectionEmpty ? null : onDeleteSelectedPieces,
          ),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(context.l10n.duplicate),
            onPressed: selectedCount == 1 ? onDuplicateSelectedPiece : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.group_work),
            label: Text(context.l10n.modifyGroup),
            onPressed: isSelectionEmpty ? null : onModifyGroupOfSelectedPieces,
          ),
        ],
      ),
    );
  }
}
