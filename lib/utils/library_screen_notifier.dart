import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../utils/app_logger.dart';

import '../database/music_piece_repository.dart';
import '../models/group.dart';
import '../models/music_piece.dart';
import '../services/library_data_manager.dart';
import '../utils/settings_manager.dart';
import '../utils/music_piece_filter.dart';


class LibraryScreenNotifier extends ChangeNotifier {
  final MusicPieceRepository _repository;
  late LibraryDataManager _libraryDataManager;
  late SettingsManager _settingsManager;

  // Notifiers for data and loading states
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier(null);
  final ValueNotifier<List<MusicPiece>> allMusicPiecesNotifier = ValueNotifier([]);
  final ValueNotifier<List<MusicPiece>> musicPiecesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Group>> groupsNotifier = ValueNotifier([]);
  final ValueNotifier<int> galleryColumnsNotifier = ValueNotifier(1);

  // Cache for filtered results per group
  final Map<String, List<MusicPiece>> _filteredResultsCache = {};
  String _lastSearchQuery = '';
  Map<String, dynamic> _lastFilterOptions = {};
  String _lastSortOption = '';

  // UI related state
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  Map<String, dynamic> _filterOptions = {'orderedTags': <String, List<String>>{}};
  String _sortOption = 'A-Z (Title)';
  bool _isMultiSelectMode = false;
  final Set<String> _selectedPieceIds = {};
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Timer? _debounceTimer;
  final FocusNode _focusNode = FocusNode();
  late PageController _pageController;
  late ScrollController _groupScrollController;
  Key _groupListKey = UniqueKey();
  String? _selectedGroupId;

  LibraryScreenNotifier(this._repository, SharedPreferences prefs) {
    _settingsManager = SettingsManager(galleryColumnsNotifier);
    _settingsManager.prefs = prefs;
    _initialize();
  }

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filterOptions => _filterOptions;
  String get sortOption => _sortOption;
  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedPieceIds => _selectedPieceIds;
  Set<LogicalKeyboardKey> get pressedKeys => _pressedKeys;
  FocusNode get focusNode => _focusNode;
  PageController get pageController => _pageController;
  ScrollController get groupScrollController => _groupScrollController;
  Key get groupListKey => _groupListKey;
  String? get selectedGroupId => _selectedGroupId;
  SharedPreferences get prefs => _settingsManager.prefs;

  bool get hasActiveFilters {
    return _filterOptions.isNotEmpty &&
        (_filterOptions['genres']?.isNotEmpty == true ||
            _filterOptions['instrumentations']?.isNotEmpty == true ||
            _filterOptions['difficulties']?.isNotEmpty == true ||
            _hasOrderedTagsFilter() ||
            _filterOptions['enablePracticeTracking'] == true ||
            _filterOptions['minPracticeCount'] != null ||
            _filterOptions['maxPracticeCount'] != null ||
            _filterOptions['minPracticeDate'] != null ||
            _filterOptions['maxPracticeDate'] != null);
  }

  bool _hasOrderedTagsFilter() {
    final orderedTags = _filterOptions['orderedTags'];
    if (orderedTags is Map<String, List<String>>) {
      return orderedTags.values.any((list) => list.isNotEmpty);
    }
    return false;
  }

  Future<void> _initialize() async {
    _pageController = PageController();
    _groupScrollController = ScrollController();
    
    _libraryDataManager = LibraryDataManager(
      _repository,
      _settingsManager.prefs,
      isLoadingNotifier,
      errorMessageNotifier,
      allMusicPiecesNotifier,
      musicPiecesNotifier,
      groupsNotifier,
      galleryColumnsNotifier,
    );
    await _libraryDataManager.loadInitialData();
    
    // Load saved sort option
    _sortOption = _settingsManager.loadSortOption();
    AppLogger.log('LibraryScreenNotifier: Loaded saved sort option: $_sortOption');
    
    // Set the first visible group as active if no group is selected
    final visibleGroups = getVisibleGroups();
    if (_selectedGroupId == null && visibleGroups.isNotEmpty) {
      _selectedGroupId = visibleGroups.first.id;
      AppLogger.log('LibraryScreenNotifier: Auto-selected first visible group on startup: ${visibleGroups.first.name}');
    }
    
    // Update the cache with initial data and load music pieces
    _updateFilteredResultsCache();
    await loadMusicPieces();
    
    _focusNode.requestFocus();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.log('LibraryScreenNotifier: dispose called');
    _pageController.dispose();
    _groupScrollController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    isLoadingNotifier.dispose();
    errorMessageNotifier.dispose();
    allMusicPiecesNotifier.dispose();
    musicPiecesNotifier.dispose();
    groupsNotifier.dispose();
    galleryColumnsNotifier.dispose();
    super.dispose();
  }

  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (!_isMultiSelectMode) {
      _selectedPieceIds.clear();
    }
    notifyListeners();
  }

  void onPieceSelected(MusicPiece piece) {
    if (_selectedPieceIds.contains(piece.id)) {
      _selectedPieceIds.remove(piece.id);
    } else {
      _selectedPieceIds.add(piece.id);
    }

    if (_selectedPieceIds.isEmpty) {
      _isMultiSelectMode = false;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateFilteredResultsCache();
      loadMusicPieces();
    });
  }

  void setFilterOptions(Map<String, dynamic> newFilterOptions) {
    _filterOptions = newFilterOptions;
    notifyListeners();
  }

  void clearFilter() {
    _filterOptions = {'orderedTags': <String, List<String>>{}};
    notifyListeners();
    _updateFilteredResultsCache();
    loadMusicPieces();
  }

  void setSortOption(String newSortOption) {
    _sortOption = newSortOption;
    // Save sort option to persistent storage
    _settingsManager.saveSortOption(newSortOption);
    notifyListeners();
    _updateFilteredResultsCache();
    loadMusicPieces();
  }

  void selectAllPieces() {
    final allPieceIds = musicPiecesNotifier.value.map((p) => p.id).toSet();
    if (_selectedPieceIds.length == allPieceIds.length) {
      _selectedPieceIds.clear();
    } else {
      _selectedPieceIds.addAll(allPieceIds);
    }
    notifyListeners();
  }

  Future<void> loadSettings() async {
    AppLogger.log('LibraryScreenNotifier: loadSettings called');
    await _settingsManager.loadGalleryColumns();
  }

  Future<void> loadGroups() async {
    AppLogger.log('LibraryScreenNotifier: loadGroups called');
    isLoadingNotifier.value = true;
    errorMessageNotifier.value = null;
    try {
      final allDbGroups = await _repository.getGroups();
      AppLogger.log('LibraryScreenNotifier: Loaded ${allDbGroups.length} groups from DB.');

      final groupSettings = _settingsManager.loadGroupOrderSettings();
      final allGroup = Group(
        id: 'all_group',
        name: 'All',
        order: groupSettings['allGroupOrder'],
        isHidden: groupSettings['allGroupIsHidden'],
      );

      final ungroupedGroup = Group(
        id: 'ungrouped_group',
        name: 'Ungrouped',
        order: groupSettings['ungroupedGroupOrder'],
        isHidden: groupSettings['ungroupedGroupIsHidden'],
      );

      List<Group> combinedGroups = [allGroup, ungroupedGroup, ...allDbGroups];

      combinedGroups.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });

      groupsNotifier.value = combinedGroups;
      AppLogger.log('LibraryScreenNotifier: All groups (including special): ${groupsNotifier.value.map((g) => '${g.name} (id: ${g.id}, order: ${g.order}, hidden: ${g.isHidden})').join(', ')}');
      
      // Check if the currently selected group is still valid
      if (_selectedGroupId != null && !groupsNotifier.value.any((g) => g.id == _selectedGroupId)) {
        _selectedGroupId = null;
      }
      
      // Reset PageController to ensure smooth transitions when groups change
      _resetPageController();
      
      _groupListKey = UniqueKey();
    } catch (e) {
      errorMessageNotifier.value = 'Failed to load groups: $e';
      AppLogger.log('LibraryScreenNotifier: Error loading groups: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> loadMusicPieces() async {
    // Check if cache needs to be updated
    if (_needsCacheUpdate()) {
      _updateFilteredResultsCache();
    }
    
    // Use cached results for the selected group
    if (_selectedGroupId != null) {
      final cachedPieces = getFilteredPiecesForGroup(_selectedGroupId!);
      musicPiecesNotifier.value = cachedPieces;
      AppLogger.log('LibraryScreenNotifier: Loaded ${cachedPieces.length} cached pieces for group $_selectedGroupId');
    } else {
      musicPiecesNotifier.value = [];
    }
    
    notifyListeners();
  }

  List<Group> getVisibleGroups() {
    return groupsNotifier.value.where((group) => !group.isHidden).toList();
  }

  /// Gets filtered and sorted pieces for a specific group from cache
  List<MusicPiece> getFilteredPiecesForGroup(String groupId) {
    return _filteredResultsCache[groupId] ?? [];
  }

  /// Checks if the cache needs to be updated based on current search/filter criteria
  bool _needsCacheUpdate() {
    return _searchQuery != _lastSearchQuery ||
           _sortOption != _lastSortOption ||
           !_areFilterOptionsEqual(_filterOptions, _lastFilterOptions);
  }

  /// Compares two filter option maps for equality
  bool _areFilterOptionsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  /// Updates the filtered results cache for all groups
  void _updateFilteredResultsCache() {
    AppLogger.log('LibraryScreenNotifier: Updating filtered results cache');
    _filteredResultsCache.clear();
    
    final allPieces = allMusicPiecesNotifier.value;
    final visibleGroups = getVisibleGroups();
    
    for (final group in visibleGroups) {
      // Filter pieces for this group
      List<MusicPiece> piecesForGroup;
      if (group.id == 'all_group') {
        piecesForGroup = List.from(allPieces);
      } else if (group.id == 'ungrouped_group') {
        piecesForGroup = allPieces.where((piece) => piece.groupIds.isEmpty).toList();
      } else {
        piecesForGroup = allPieces.where((piece) => piece.groupIds.contains(group.id)).toList();
      }
      
      // Apply search and filter
      final filter = MusicPieceFilter(
        searchQuery: _searchQuery,
        filterOptions: _filterOptions,
        sortOption: _sortOption,
      );
      final filteredAndSortedPieces = filter.filterAndSort(piecesForGroup);
      
      _filteredResultsCache[group.id] = filteredAndSortedPieces;
      AppLogger.log('LibraryScreenNotifier: Cached ${filteredAndSortedPieces.length} pieces for group ${group.name}');
    }
    
    // Update last known criteria
    _lastSearchQuery = _searchQuery;
    _lastFilterOptions = Map.from(_filterOptions);
    _lastSortOption = _sortOption;
  }

  void _resetPageController() {
    AppLogger.log('LibraryScreenNotifier: _resetPageController called');
    final visibleGroups = getVisibleGroups();
    AppLogger.log('LibraryScreenNotifier: Visible groups: ${visibleGroups.map((g) => g.name).join(', ')}');
    
    // If the currently selected group is not in visible groups, select the first visible group
    if (_selectedGroupId != null && !visibleGroups.any((g) => g.id == _selectedGroupId)) {
      if (visibleGroups.isNotEmpty) {
        _selectedGroupId = visibleGroups.first.id;
        AppLogger.log('LibraryScreenNotifier: Selected first visible group: ${visibleGroups.first.name}');
      } else {
        _selectedGroupId = null;
        AppLogger.log('LibraryScreenNotifier: No visible groups, cleared selection');
      }
    }
    
    // If no group is selected and there are visible groups, select the first one
    if (_selectedGroupId == null && visibleGroups.isNotEmpty) {
      _selectedGroupId = visibleGroups.first.id;
      AppLogger.log('LibraryScreenNotifier: Auto-selected first visible group: ${visibleGroups.first.name}');
    }
  }

  void onGroupSelected(String? groupId, {bool animate = true}) {
    AppLogger.log('LibraryScreenNotifier: onGroupSelected called with groupId: $groupId, animate: $animate');
    
    // Avoid unnecessary updates if the group hasn't changed
    if (_selectedGroupId == groupId) {
      return;
    }

    _selectedGroupId = groupId;
    final visibleGroups = getVisibleGroups();
    final index = visibleGroups.indexWhere((g) => g.id == groupId);
    AppLogger.log('LibraryScreenNotifier: Found group at index: $index in visible groups: ${visibleGroups.map((g) => g.name).join(', ')}');
    
    if (animate && pageController.hasClients && index != -1) {
      // Use jumpToPage for instant transition to avoid scrolling through intermediate pages
      pageController.jumpToPage(index);
    }
    
    // Auto-scroll the group title into view
    _scrollGroupIntoView(index);
    
    // Update music pieces from cache instead of re-filtering
    if (groupId != null) {
      final cachedPieces = getFilteredPiecesForGroup(groupId);
      musicPiecesNotifier.value = cachedPieces;
      AppLogger.log('LibraryScreenNotifier: Updated music pieces from cache for group $groupId: ${cachedPieces.length} pieces');
    } else {
      musicPiecesNotifier.value = [];
    }
    
    notifyListeners();
  }

  /// Scrolls the selected group chip into view in the horizontal scroll view
  void _scrollGroupIntoView(int groupIndex) {
    if (groupIndex == -1 || !_groupScrollController.hasClients) return;
    
    // Calculate the approximate position of the group chip
    // Each chip has padding and we need to account for the chip width
    final chipWidth = 120.0; // Approximate width of a group chip
    final chipPadding = 8.0; // Padding between chips
    final targetOffset = groupIndex * (chipWidth + chipPadding);
    
    // Animate to the target position
    _groupScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    AppLogger.log('LibraryScreenNotifier: Scrolling group at index $groupIndex to offset $targetOffset');
  }

  Future<void> reloadData() async {
    AppLogger.log('LibraryScreenNotifier: reloadData called');
    await _libraryDataManager.loadGroups();
    await _libraryDataManager.loadMusicPieces(
      selectedGroupId: _selectedGroupId,
      searchQuery: _searchQuery,
      filterOptions: _filterOptions,
      sortOption: _sortOption,
    );
    
    // Update the cache with new data
    _updateFilteredResultsCache();
    
    await loadSettings(); // Call the notifier's loadSettings method
    AppLogger.log('LibraryScreenNotifier: reloadData completed, notifying listeners');
    AppLogger.log('LibraryScreenNotifier: Final galleryColumns value: ${galleryColumnsNotifier.value}');
    notifyListeners();
  }

  /// Reloads only the settings and forces a UI rebuild
  Future<void> reloadSettings() async {
    AppLogger.log('LibraryScreenNotifier: reloadSettings called');
    await loadSettings();
    AppLogger.log('LibraryScreenNotifier: reloadSettings completed, notifying listeners');
    notifyListeners();
  }
}
