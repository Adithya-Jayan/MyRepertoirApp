import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../database/music_piece_repository.dart';

import '../utils/app_logger.dart';
import '../utils/library_screen_notifier.dart';

import './library_app_bar.dart';
import './library_bottom_app_bar.dart';
import './library_actions.dart';
import './library_body.dart';

import './add_edit_piece_screen.dart';

/// The main screen of the application, displaying the user's music repertoire.
///
/// This screen allows users to view, search, filter, sort, and manage their
/// music pieces. It supports single and multi-selection modes for batch operations.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.log('LibraryScreen: build called');
    return ChangeNotifierProvider(
      create: (context) => LibraryScreenNotifier(MusicPieceRepository()),
      child: Consumer<LibraryScreenNotifier>(
        builder: (context, notifier, child) {
          if (!notifier.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final visibleGroups = notifier.getVisibleGroups();
          return KeyboardListener(
            focusNode: notifier.focusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                notifier.pressedKeys.add(event.logicalKey);
              } else if (event is KeyUpEvent) {
                notifier.pressedKeys.remove(event.logicalKey);
              }
            },
            child: Scaffold(
              appBar: LibraryAppBar(
                isMultiSelectMode: notifier.isMultiSelectMode,
                searchQuery: notifier.searchQuery,
                onSearchChanged: notifier.setSearchQuery,
                hasActiveFilters: notifier.hasActiveFilters,
                filterOptions: notifier.filterOptions,
                onFilterOptionsChanged: notifier.setFilterOptions,
                onApplyFilter: notifier.loadMusicPieces,
                onClearFilter: notifier.clearFilter,
                sortOption: notifier.sortOption,
                onSortOptionChanged: notifier.setSortOption,
                onToggleMultiSelectMode: notifier.toggleMultiSelectMode,
                selectedPieceCount: notifier.selectedPieceIds.length,
                onSelectAll: notifier.selectAllPieces,
                repository: MusicPieceRepository(),
                prefs: notifier.prefs,
                onSettingsChanged: notifier.reloadData,
              ),
              body: LibraryBody(
                visibleGroups: visibleGroups,
                selectedGroupId: notifier.selectedGroupId,
                allMusicPieces: notifier.allMusicPiecesNotifier.value,
                musicPieces: notifier.musicPiecesNotifier.value,
                isLoading: notifier.isLoadingNotifier.value,
                errorMessage: notifier.errorMessageNotifier.value,
                galleryColumns: notifier.galleryColumnsNotifier.value,
                groupListKey: notifier.groupListKey,
                pageController: notifier.pageController,
                groupScrollController: notifier.groupScrollController,
                isMultiSelectMode: notifier.isMultiSelectMode,
                selectedPieceIds: notifier.selectedPieceIds,
                pressedKeys: notifier.pressedKeys,
                onPieceSelected: notifier.onPieceSelected,
                onReloadData: notifier.reloadData,
                onToggleMultiSelectMode: notifier.toggleMultiSelectMode,
                onGroupSelected: notifier.onGroupSelected,
              ),
              bottomNavigationBar: notifier.isMultiSelectMode
                  ? LibraryBottomAppBar(
                      isMultiSelectMode: notifier.isMultiSelectMode,
                      onDeleteSelectedPieces: () {
                        LibraryActions(
                          repository: MusicPieceRepository(),
                          onReloadMusicPieces: notifier.loadMusicPieces,
                          onToggleMultiSelectMode: notifier.toggleMultiSelectMode,
                          allMusicPieces: notifier.allMusicPiecesNotifier.value,
                        ).deleteSelectedPieces(context, notifier.selectedPieceIds);
                      },
                      onModifyGroupOfSelectedPieces: () {
                        LibraryActions(
                          repository: MusicPieceRepository(),
                          onReloadMusicPieces: notifier.loadMusicPieces,
                          onToggleMultiSelectMode: notifier.toggleMultiSelectMode,
                          allMusicPieces: notifier.allMusicPiecesNotifier.value,
                        ).modifyGroupOfSelectedPieces(context, notifier.selectedPieceIds, notifier.groupsNotifier.value);
                      },
                      isSelectionEmpty: notifier.selectedPieceIds.isEmpty,
                    )
                  : null,
              floatingActionButton: notifier.isMultiSelectMode
                  ? null
                  : FloatingActionButton(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool?>(
                          MaterialPageRoute(builder: (context) => AddEditPieceScreen(selectedGroupId: notifier.selectedGroupId)),
                        );
                        if (result == true) {
                          await notifier.reloadData();
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
            ),
          );
        },
      ),
    );
  }
}