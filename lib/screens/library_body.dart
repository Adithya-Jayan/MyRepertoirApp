import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repertoire/models/group.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/screens/music_piece_grid_view.dart';

import '../utils/app_logger.dart';

class LibraryBody extends StatelessWidget {
  final List<Group> visibleGroups;
  final String? selectedGroupId;
  final List<MusicPiece> allMusicPieces;
  final List<MusicPiece> musicPieces;
  final bool isLoading;
  final String? errorMessage;
  final int galleryColumns;
  final Key groupListKey;
  final PageController pageController;
  final ScrollController groupScrollController;
  final bool isMultiSelectMode;
  final Set<String> selectedPieceIds;
  final Set<LogicalKeyboardKey> pressedKeys;
  final Function(MusicPiece) onPieceSelected;
  final VoidCallback onReloadData;
  final VoidCallback onToggleMultiSelectMode;
  final ValueChanged<String> onGroupSelected;

  const LibraryBody({
    super.key,
    required this.visibleGroups,
    required this.selectedGroupId,
    required this.allMusicPieces,
    required this.musicPieces,
    required this.isLoading,
    required this.errorMessage,
    required this.galleryColumns,
    required this.groupListKey,
    required this.pageController,
    required this.groupScrollController,
    required this.isMultiSelectMode,
    required this.selectedPieceIds,
    required this.pressedKeys,
    required this.onPieceSelected,
    required this.onReloadData,
    required this.onToggleMultiSelectMode,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.log('LibraryBody: build called');
    return Column(
      children: [
        // Group Toggling Bar (horizontal scrollable chips).
        visibleGroups.isNotEmpty
            ? SingleChildScrollView(
                key: groupListKey, // Use the new key to force rebuild of the group list.
                controller: groupScrollController, // Attach the scroll controller for horizontal scrolling.
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: visibleGroups.map((group) {
                    if (visibleGroups.length == 1) {
                      return const SizedBox.shrink();
                    }
                    final isSelected = selectedGroupId == group.id || (selectedGroupId == null && group.id == 'all_group');
                    int pieceCount = 0;
                    if (group.id == 'all_group') {
                      pieceCount = allMusicPieces.length;
                    } else if (group.id == 'ungrouped_group') {
                      pieceCount = allMusicPieces.where((p) => p.groupIds.isEmpty).length;
                    } else {
                      pieceCount = allMusicPieces.where((p) => p.groupIds.contains(group.id)).length;
                    }

                    return Padding(
                      key: ValueKey(group.id),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: visibleGroups.length == 1 ? const SizedBox.shrink() : Text('${group.name} ($pieceCount)'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            final index = visibleGroups.indexOf(group);
                            pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.ease);
                            // Add a callback to notify the parent about the selected group change
                            onGroupSelected(group.id);
                          }
                        },
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              )
            : const SizedBox.shrink(), // Hide the group bar if no groups are available.
          Expanded(
            // PageView to display music pieces for each selected group.
            child: PageView.builder(
              controller: pageController,
              itemCount: visibleGroups.isEmpty ? 1 : visibleGroups.length,
              onPageChanged: (index) {
                onGroupSelected(visibleGroups[index].id);
              },
              itemBuilder: (context, pageIndex) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (errorMessage != null) {
                  return Center(child: Text(errorMessage!));
                } else {
                  // Determine the group ID for the current page.
                  String? currentPageGroupId;
                  if (visibleGroups.isNotEmpty) {
                    currentPageGroupId = visibleGroups[pageIndex].id;
                  } else {
                    // If no groups are visible, show an empty gallery.
                    return const Center(child: Text('No visible groups.'));
                  }

                  // Filter music pieces for the current page's group.
                  final musicPiecesForPage = allMusicPieces.where((piece) {
                    if (currentPageGroupId == 'all_group') {
                      return true; // Show all pieces for "All" group.
                    } else if (currentPageGroupId == 'ungrouped_group') {
                      return piece.groupIds.isEmpty; // Show pieces with no group
                    } else {
                      return piece.groupIds.contains(currentPageGroupId);
                    }
                  }).toList();

                  // Apply search and filter options to the current page's pieces.
                  // This filtering logic should ideally be passed down or handled by a provider.
                  // For now, we'll assume `musicPieces` already reflects the filtered state.
                  final filteredAndSortedPieces = musicPiecesForPage; // Placeholder, actual filtering happens in parent

                  if (filteredAndSortedPieces.isEmpty) {
                    return const Center(child: Text('No music pieces found in this group.'));
                  }

                  return MusicPieceGridView(
                    musicPieces: filteredAndSortedPieces,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    galleryColumns: galleryColumns,
                    selectedPieceIds: selectedPieceIds,
                    pressedKeys: pressedKeys,
                    isMultiSelectMode: isMultiSelectMode,
                    onPieceSelected: onPieceSelected,
                    onReloadData: onReloadData,
                    onToggleMultiSelectMode: onToggleMultiSelectMode,
                    currentPageGroupId: currentPageGroupId,
                  );
                }
              },
            ),
          ),
        ],
    );
  }
}
