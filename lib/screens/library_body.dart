import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repertoire/models/group.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/screens/music_piece_grid_view.dart';

class LibraryBody extends StatefulWidget {
  final List<Group> visibleGroups;
  final String? selectedGroupId;
  final List<MusicPiece> allMusicPieces;
  final List<MusicPiece> musicPieces;
  final bool isLoading;
  final String? errorMessage;
  final int galleryColumns;
  final Key groupListKey;
  final bool isMultiSelectMode;
  final Set<String> selectedPieceIds;
  final Set<LogicalKeyboardKey> pressedKeys;
  final Function(MusicPiece) onPieceSelected;
  final VoidCallback onReloadData;
  final VoidCallback onToggleMultiSelectMode;
  final void Function(String?) onGroupSelected;
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

  @override
  void initState() {
    super.initState();
    _initTabController();
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
    
    bool groupsChanged = oldWidget.visibleGroups.length != widget.visibleGroups.length ||
        !oldWidget.visibleGroups.every((g) => widget.visibleGroups.any((ng) => ng.id == g.id));

    if (groupsChanged) {
      final oldController = _tabController;
      oldController?.removeListener(_onTabChanged);
      _initTabController();
      if (oldController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          oldController.dispose();
        });
      }
    } else if (widget.selectedGroupId != oldWidget.selectedGroupId && widget.selectedGroupId != null) {
      final index = widget.visibleGroups.indexWhere((g) => g.id == widget.selectedGroupId);
      if (index != -1 && _tabController != null && _tabController!.index != index) {
        _tabController!.animateTo(index);
      }
    }
  }

  void _onTabChanged() {
    if (_tabController == null || !_tabController!.indexIsChanging) return;
    
    final newIndex = _tabController!.index;
    if (widget.visibleGroups.isNotEmpty && newIndex < widget.visibleGroups.length) {
      final newGroupId = widget.visibleGroups[newIndex].id;
      if (widget.selectedGroupId != newGroupId) {
        widget.onGroupSelected(newGroupId);
      }
    }
  }

  @override
  void dispose() {
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
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              key: ValueKey('tabbar_${widget.visibleGroups.length}'), // Force rebuild when count changes
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(179),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
          if (_tabController == null)
            const Expanded(child: Center(child: Text("No visible groups.")))
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.visibleGroups.map((group) {
                    if (widget.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (widget.errorMessage != null) {
                      return Center(child: Text(widget.errorMessage!));
                    }

                    final filteredAndSortedPieces = widget.getFilteredPiecesForGroup(group.id);
                    
                    if (filteredAndSortedPieces.isEmpty) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const Center(child: Text('This group is empty.')),
                      );
                    }

                    return MusicPieceGridView(
                      key: ValueKey('grid_${group.id}_${widget.galleryColumns}'),
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
                      currentPageGroupId: group.id,
                    );
                }).toList(),
              ),
            ),
      ],
    );
  }
}
