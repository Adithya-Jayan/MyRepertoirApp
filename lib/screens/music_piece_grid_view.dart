import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/screens/music_piece_card.dart';
import 'package:repertoire/screens/piece_detail_screen.dart';

class MusicPieceGridView extends StatelessWidget {
  final List<MusicPiece> musicPieces;
  final bool isLoading;
  final String? errorMessage;
  final int galleryColumns;
  final Set<String> selectedPieceIds;
  final Set<LogicalKeyboardKey> pressedKeys;
  final bool isMultiSelectMode;
  final Function(MusicPiece) onPieceSelected;
  final VoidCallback onReloadData;
  final VoidCallback onToggleMultiSelectMode;
  final String? currentPageGroupId; // Added to provide a unique key for GridView

  const MusicPieceGridView({
    super.key,
    required this.musicPieces,
    required this.isLoading,
    required this.errorMessage,
    required this.galleryColumns,
    required this.selectedPieceIds,
    required this.pressedKeys,
    required this.isMultiSelectMode,
    required this.onPieceSelected,
    required this.onReloadData,
    required this.onToggleMultiSelectMode,
    this.currentPageGroupId, // Made optional
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    } else if (musicPieces.isEmpty) {
      return const Center(child: Text('This group is empty.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        onReloadData();
      },
      child: GridView.builder(
        key: ValueKey('grid_${currentPageGroupId}_$galleryColumns'), // More stable key
        padding: const EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: galleryColumns, // Number of columns in the grid.
          crossAxisSpacing: 2.0,
          mainAxisSpacing: 4.0,
          childAspectRatio: 1.0, // Aspect ratio for each grid item (square).
        ),
        itemCount: musicPieces.length,
        itemBuilder: (context, index) {
          final piece = musicPieces[index];
          final isSelected = selectedPieceIds.contains(piece.id);
          return MusicPieceCard(
            key: ValueKey('card_${piece.id}_$isSelected'), // Add key for better performance
            piece: piece,
            isSelected: isSelected,
            onTap: () async {
              // Check if Shift key is pressed for multi-selection.
              final isShiftPressed = pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
                  pressedKeys.contains(LogicalKeyboardKey.shiftRight);

              if (isShiftPressed) {
                if (!isMultiSelectMode) {
                  onToggleMultiSelectMode(); // Enter multi-select mode if not already in it.
                }
                onPieceSelected(piece); // Select/deselect the piece.
              } else if (isMultiSelectMode) {
                onPieceSelected(piece); // Select/deselect the piece in multi-select mode.
              } else {
                // Navigate to PieceDetailScreen in single-selection mode.
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PieceDetailScreen(musicPiece: piece),
                  ),
                );
                onReloadData(); // Reload data after returning from detail screen.
              }
            },
            onLongPress: () {
              // Enter multi-select mode on long press and select the piece.
              if (!isMultiSelectMode) {
                onToggleMultiSelectMode();
              }
              onPieceSelected(piece);
            },
          );
        },
      ),
    );
  }
}
