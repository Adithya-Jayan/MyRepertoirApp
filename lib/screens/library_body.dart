import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repertoire/models/group.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/screens/music_piece_grid_view.dart';
import 'package:repertoire/utils/sensitive_page_scroll_physics.dart';

class LibraryBody extends StatefulWidget {
  final List<Group> visibleGroups;
  final String? selectedGroupId;
  final List<MusicPiece> allMusicPieces;
  final List<MusicPiece> musicPieces;
  final bool isLoading;
  final String? errorMessage;
  final int galleryColumns;
  final Key groupListKey;
  final PageController pageController;
  final bool isMultiSelectMode;
  final Set<String> selectedPieceIds;
  final Set<LogicalKeyboardKey> pressedKeys;
  final Function(MusicPiece) onPieceSelected;
  final VoidCallback onReloadData;
  final VoidCallback onToggleMultiSelectMode;
  final void Function(String, {bool animate}) onGroupSelected;
  final String searchQuery;
  final Map<String, dynamic> filterOptions;
  final String sortOption;
  final List<MusicPiece> Function(String) getFilteredPiecesForGroup;

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
    required this.isMultiSelectMode,
    required this.selectedPieceIds,
    required this.pressedKeys,
    required this.onPieceSelected,
    required this.onReloadData,
    required this.onToggleMultiSelectMode,
    required this.onGroupSelected,
    required this.searchQuery,
    required this.filterOptions,
    required this.sortOption,
    required this.getFilteredPiecesForGroup,
  });

  @override
  State<LibraryBody> createState() => _LibraryBodyState();
}

class _LibraryBodyState extends State<LibraryBody> with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initTabController();
    widget.pageController.addListener(_onPageScroll);
  }

  void _initTabController() {
    if (widget.visibleGroups.isEmpty) return;

    int initialIndex = 0;
    if (widget.selectedGroupId != null) {
      initialIndex = widget.visibleGroups.indexWhere((g) => g.id == widget.selectedGroupId);
      if (initialIndex == -1) initialIndex = 0;
    }

    _tabController = TabController(
      length: widget.visibleGroups.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    _tabController!.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(LibraryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Re-initialize TabController if the number of groups changed
    if (oldWidget.visibleGroups.length != widget.visibleGroups.length) {
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();
      _initTabController();
    } 
    // Sync TabController if the selected group changed externally
    else if (widget.selectedGroupId != oldWidget.selectedGroupId && widget.selectedGroupId != null) {
      final index = widget.visibleGroups.indexWhere((g) => g.id == widget.selectedGroupId);
      if (index != -1 && _tabController != null && _tabController!.index != index) {
        _isSyncing = true;
        _tabController!.animateTo(index);
        _isSyncing = false;
      }
    }
  }

  void _onTabChanged() {
    if (_tabController != null && _tabController!.indexIsChanging && !_isSyncing) {
      _isSyncing = true;
      widget.onGroupSelected(widget.visibleGroups[_tabController!.index].id, animate: true);
      _isSyncing = false;
    }
  }

  void _onPageScroll() {
    // Completely decoupled from active swipes to prevent premature TabBar movement.
    // The TabBar will only update its visual state once the page is committed in onPageChanged.
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageScroll);
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Group Toggling TabBar.
        if (widget.visibleGroups.length > 1 && _tabController != null)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.2),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              // Use a more subtle splash effect for a premium feel
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: widget.visibleGroups.map((group) {
                final pieceCount = widget.getFilteredPiecesForGroup(group.id).length;
                return Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text('${group.name} ($pieceCount)'),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            // PageView to display music pieces for each selected group.
            child: PageView.builder(
              controller: widget.pageController,
              itemCount: widget.visibleGroups.length,
              physics: const SensitivePageScrollPhysics(),
              // Enabled implicit scrolling for a more fluid feel; 
              // RepaintBoundaries and cacheExtent in GridView should keep it smooth.
              allowImplicitScrolling: true,
              padEnds: false,
              onPageChanged: (index) {
                if (widget.visibleGroups.isNotEmpty && index < widget.visibleGroups.length) {
                  if (!_isSyncing) {
                    _isSyncing = true;
                    // Force the TabController to sync ONLY once the page is fully settled
                    // Increased duration and added curve for a more visible, premium feel
                    _tabController?.animateTo(
                      index, 
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                    widget.onGroupSelected(widget.visibleGroups[index].id, animate: false);
                    // Add subtle haptic feedback when the tab actually settles
                    HapticFeedback.selectionClick();
                    _isSyncing = false;
                  }
                }
              },
              itemBuilder: (context, pageIndex) {
                if (widget.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (widget.errorMessage != null) {
                  return Center(child: Text(widget.errorMessage!));
                } else {
                  // Determine the group ID for the current page.
                  String? currentPageGroupId;
                  if (widget.visibleGroups.isNotEmpty) {
                    currentPageGroupId = widget.visibleGroups[pageIndex].id;
                  } else {
                    // If no groups are visible, show an empty gallery.
                    return const Center(child: Text('No visible groups.'));
                  }

                  // Get filtered pieces from cache instead of filtering on every build
                  final filteredAndSortedPieces = widget.getFilteredPiecesForGroup(currentPageGroupId);
                  
                  if (filteredAndSortedPieces.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6, // Ensure minimum height for refresh
                      child: const Center(child: Text('This group is empty.')),
                    );
                  }

                  return MusicPieceGridView(
                    key: ValueKey('grid_${currentPageGroupId}_${widget.galleryColumns}_$pageIndex'),
                    musicPieces: filteredAndSortedPieces,
                    isLoading: widget.isLoading,
                    errorMessage: widget.errorMessage,
                    galleryColumns: widget.galleryColumns,
                    selectedPieceIds: widget.selectedPieceIds,
                    pressedKeys: widget.pressedKeys,
                    isMultiSelectMode: widget.isMultiSelectMode,
                    onPieceSelected: widget.onPieceSelected,
                    onReloadData: widget.onReloadData,
                    onToggleMultiSelectMode: widget.onToggleMultiSelectMode,
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
