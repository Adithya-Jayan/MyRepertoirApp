import 'package:flutter/material.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/utils/app_logger.dart';

class LibraryActions {
  final MusicPieceRepository repository;
  final VoidCallback onReloadMusicPieces;
  final VoidCallback onToggleMultiSelectMode;
  final List<MusicPiece> allMusicPieces;

  LibraryActions({
    required this.repository,
    required this.onReloadMusicPieces,
    required this.onToggleMultiSelectMode,
    required this.allMusicPieces,
  });

  /// Deletes all currently selected music pieces after user confirmation.
  Future<void> deleteSelectedPieces(BuildContext context, Set<String> selectedPieceIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete ${selectedPieceIds.length} selected item(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await repository.deleteMusicPieces(selectedPieceIds.toList()); // Delete the selected music pieces from the database.
        onToggleMultiSelectMode(); // Exit multi-select mode after deletion.
        onReloadMusicPieces(); // Reload music pieces to update the UI.
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting pieces: $e')),
        );
      }
    }
  }

  Future<void> modifyGroupOfSelectedPieces(BuildContext context, Set<String> selectedPieceIds, List<dynamic> groups) async {
    await showDialog(
      context: context,
      builder: (context) {
        // Create a temporary map to hold pending changes
        final Map<String, bool?> pendingGroupChanges = {}; // Use bool? to represent tristate

        return AlertDialog(
          title: const Text('Modify Groups'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Re-evaluate selectedPieces here on each setState
              final currentSelectedPiecesInDialog = allMusicPieces.where((p) => selectedPieceIds.contains(p.id)).toList();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: groups.where((group) => group.id != 'all_group' && group.id != 'ungrouped_group').map((group) {
                    // Determine initial state
                    final isSelectedInAllInitial = currentSelectedPiecesInDialog.every((p) => p.groupIds.contains(group.id));
                    final isSelectedInSomeInitial = currentSelectedPiecesInDialog.any((p) => p.groupIds.contains(group.id)) && !isSelectedInAllInitial;

                    AppLogger.log('--- Group Debug ---');
                    print('Group: ${group.name} (ID: ${group.id})');
                    AppLogger.log('  isSelectedInAllInitial: $isSelectedInAllInitial');
                    AppLogger.log('  isSelectedInSomeInitial: $isSelectedInSomeInitial');

                    // Determine current checkbox value based on pending changes or initial state
                    bool? checkboxValue;
                    if (pendingGroupChanges.containsKey(group.id)) {
                      checkboxValue = pendingGroupChanges[group.id];
                    } else {
                      if (isSelectedInAllInitial) {
                        checkboxValue = true;
                      } else if (isSelectedInSomeInitial) {
                        checkboxValue = null; // Tristate
                      } else {
                        checkboxValue = false;
                      }
                    }
                    AppLogger.log('  Calculated checkboxValue: $checkboxValue');

                    return CheckboxListTile(
                      title: Text(group.name),
                      value: checkboxValue,
                      tristate: true, // Always enable tristate
                      onChanged: (bool? newValueFromCheckbox) {
                        setState(() {
                          bool? currentEffectiveValue;
                          if (pendingGroupChanges.containsKey(group.id)) {
                            currentEffectiveValue = pendingGroupChanges[group.id];
                          } else {
                            // Determine initial state if no pending change
                            final isSelectedInAllInitial = currentSelectedPiecesInDialog.every((p) => p.groupIds.contains(group.id));
                            final isSelectedInSomeInitial = currentSelectedPiecesInDialog.any((p) => p.groupIds.contains(group.id)) && !isSelectedInAllInitial;
                            if (isSelectedInAllInitial) {
                              currentEffectiveValue = true;
                            } else if (isSelectedInSomeInitial) {
                              currentEffectiveValue = null;
                            } else {
                              currentEffectiveValue = false;
                            }
                          }

                          if (currentEffectiveValue == true) {
                            // If currently checked, uncheck it
                            pendingGroupChanges[group.id] = false;
                          } else {
                            // If currently unchecked or tristate, check it
                            pendingGroupChanges[group.id] = true;
                          }
                          AppLogger.log('  Pending change for ${group.name}: ${pendingGroupChanges[group.id]}');
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel button
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Apply all pending changes
                for (final entry in pendingGroupChanges.entries) {
                  if (entry.value != null) { // Only apply if a definite state (true/false) is chosen
                    await repository.updateGroupMembershipForPieces(
                      selectedPieceIds.toList(),
                      entry.key,
                      entry.value!,
                    );
                  }
                }
                onReloadMusicPieces(); // Refresh the data after applying changes
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    onToggleMultiSelectMode(); // Exit multi-select mode after modification
  }
}
