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
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with WidgetsBindingObserver {
  bool _hasReturnedFromSettings = false;
  bool _shouldReloadOnNextBuild = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should reload data (e.g., when returning from settings)
    if (_shouldReloadOnNextBuild) {
      _shouldReloadOnNextBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final notifier = Provider.of<LibraryScreenNotifier>(context, listen: false);
          AppLogger.log('LibraryScreen: Reloading data in didChangeDependencies');
          notifier.reloadData();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _hasReturnedFromSettings) {
      AppLogger.log('LibraryScreen: App resumed, triggering data reload');
      _hasReturnedFromSettings = false;
      // Trigger reload after a short delay to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final notifier = Provider.of<LibraryScreenNotifier>(context, listen: false);
          notifier.reloadData();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LibraryScreenNotifier(MusicPieceRepository()),
      child: Consumer<LibraryScreenNotifier>(
        builder: (context, notifier, child) {
          // Force rebuild when gallery columns change
          final galleryColumns = notifier.galleryColumnsNotifier.value;
          if (!notifier.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final visibleGroups = notifier.getVisibleGroups();
          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) async {
              AppLogger.log('LibraryScreen: PopScope triggered - didPop: $didPop, result: $result');
              if (didPop) {
                // Check if we're returning from a restore operation
                if (result == true) {
                  AppLogger.log('LibraryScreen: Returning from restore operation, triggering full data reload');
                  _shouldReloadOnNextBuild = true;
                  // Mark that we've returned from settings to ensure reload
                  _hasReturnedFromSettings = true;
                } else {
                  // Mark that we've returned from settings
                  _hasReturnedFromSettings = true;
                  // Always refresh data when returning to the library screen
                  // This ensures the gallery updates regardless of how the user navigates back
                  AppLogger.log('LibraryScreen: Reloading data after navigation return');
                  await notifier.reloadData();
                  AppLogger.log('LibraryScreen: Data reload completed');
                }
              }
            },
            child: KeyboardListener(
              focusNode: notifier.focusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  notifier.pressedKeys.add(event.logicalKey);
                } else if (event is KeyUpEvent) {
                  notifier.pressedKeys.remove(event.logicalKey);
                }
              },
              child: SafeArea(
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
              body: ValueListenableBuilder<int>(
                valueListenable: notifier.galleryColumnsNotifier,
                builder: (context, galleryColumns, child) {
                  AppLogger.log('LibraryScreen: ValueListenableBuilder rebuild with galleryColumns: $galleryColumns');
                  return RefreshIndicator(
                    onRefresh: () async {
                      AppLogger.log('LibraryScreen: Swipe-to-refresh triggered');
                      await notifier.reloadData();
                    },
                    child: LibraryBody(
                      key: ValueKey('library_body_$galleryColumns'), // Force rebuild when columns change
                      visibleGroups: visibleGroups,
                      selectedGroupId: notifier.selectedGroupId,
                      allMusicPieces: notifier.allMusicPiecesNotifier.value,
                      musicPieces: notifier.musicPiecesNotifier.value,
                      isLoading: notifier.isLoadingNotifier.value,
                      errorMessage: notifier.errorMessageNotifier.value,
                      galleryColumns: galleryColumns,
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
                      searchQuery: notifier.searchQuery,
                      filterOptions: notifier.filterOptions,
                      sortOption: notifier.sortOption,
                      getFilteredPiecesForGroup: notifier.getFilteredPiecesForGroup,
                    ),
                  );
                },
              ),
              bottomNavigationBar: notifier.isMultiSelectMode
                  ? LibraryBottomAppBar(
                      isMultiSelectMode: notifier.isMultiSelectMode,
                      onDeleteSelectedPieces: () {
                        LibraryActions(
                          repository: MusicPieceRepository(),
                          onReloadMusicPieces: notifier.reloadData, // CHANGED from loadMusicPieces
                          onToggleMultiSelectMode: notifier.toggleMultiSelectMode,
                          allMusicPieces: notifier.allMusicPiecesNotifier.value,
                        ).deleteSelectedPieces(context, notifier.selectedPieceIds);
                      },
                      onModifyGroupOfSelectedPieces: () {
                        LibraryActions(
                          repository: MusicPieceRepository(),
                          onReloadMusicPieces: notifier.reloadData, // CHANGED from loadMusicPieces
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
            ),
          );
        },
      ),
    );
  }
}