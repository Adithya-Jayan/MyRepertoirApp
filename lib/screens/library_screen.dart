import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

import '../database/music_piece_repository.dart';
import '../models/group.dart';
import '../models/music_piece.dart';

import './library_app_bar.dart';
import './library_bottom_app_bar.dart';
import './library_actions.dart';
import './library_body.dart';
import './library_utils.dart';
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

/// The state class for [LibraryScreen].
/// Manages the data, UI state, and interactions for the music repertoire display.
class _LibraryScreenState extends State<LibraryScreen> {
  /// Repository for interacting with music piece data in the database.
  final MusicPieceRepository _repository = MusicPieceRepository();

  /// Stores all music pieces loaded from the database, before any filtering.
  List<MusicPiece> _allMusicPieces = [];

  /// The list of music pieces currently displayed in the UI, after applying filters and sorting.
  List<MusicPiece> _musicPieces = [];

  /// The current search query entered by the user.
  String _searchQuery = '';

  /// A map storing the currently active filter options.
  Map<String, dynamic> _filterOptions = {};

  /// Returns true if any filter options are currently active.
  bool get _hasActiveFilters {
    // Check if any filter option other than 'orderedTags' is non-null or non-empty.
    final hasNonTagFilters = _filterOptions.entries.any((entry) {
      if (entry.key == 'orderedTags') {
        // For 'orderedTags', check if the map is not empty.
        return (entry.value as Map<String, List<String>>).isNotEmpty;
      } else {
        // For other filters, check if the value is not null and not an empty string.
        return entry.value != null && entry.value != '';
      }
    });

    // Also check if the search query is not empty.
    final hasSearchQuery = _searchQuery.isNotEmpty;

    return hasNonTagFilters || hasSearchQuery;
  }

  /// The currently selected sorting option for music pieces (e.g., alphabetical, last practiced).
  String _sortOption = 'alphabetical_asc';

  /// List of all user-defined groups, excluding the default group.
  List<Group> _groups = [];

  /// The ID of the currently selected group for filtering music pieces.
  String? _selectedGroupId;

  /// Instance of SharedPreferences for persistent storage of user preferences.
  late SharedPreferences _prefs;

  /// Flag to indicate if data is currently being loaded from the database.
  bool _isLoading = true;

  /// Stores any error messages that occur during data loading or other operations.
  String? _errorMessage;

  /// The number of columns to display in the music piece gallery grid.
  int _galleryColumns = 1;

  /// A unique key used to force a rebuild of the group list UI when groups are modified.
  Key _groupListKey = UniqueKey();

  /// Controller for the PageView widget, used for navigating between different group views.
  late PageController _pageController;

  /// Controller for the horizontal scrollable list of group chips.
  late ScrollController _groupScrollController;

  /// Flag indicating whether multi-selection mode is currently active.
  bool _isMultiSelectMode = false;

  /// A set containing the IDs of music pieces currently selected in multi-selection mode.
  final Set<String> _selectedPieceIds = {};

  /// Focus node used to manage keyboard focus for the RawKeyboardListener.
  final FocusNode _focusNode = FocusNode();

  /// A set to keep track of currently pressed logical keyboard keys.
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize the PageController for managing page views.
    _pageController = PageController();
    // Initialize the ScrollController for the horizontal group chips.
    _groupScrollController = ScrollController();
    // Asynchronously initialize SharedPreferences.
    await _initSharedPreferences();
    // Load initial data for the screen (groups, music pieces, settings).
    await _loadInitialData();
    // Request focus for the keyboard listener to capture key events.
    _focusNode.requestFocus();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This line is commented out as it might cause issues with focus management
    // if not carefully handled with other focus-related widgets.
    // FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose the PageController to release resources.
    _groupScrollController.dispose(); // Dispose the ScrollController for group chips.
    _focusNode.dispose(); // Dispose the FocusNode.
    super.dispose();
  }

  /// Toggles the multi-selection mode on and off.
  /// When exiting multi-selection mode, all selected pieces are deselected.
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedPieceIds.clear(); // Clear all selected piece IDs when exiting multi-select mode.
      }
    });
  }

  /// Handles the selection or deselection of a music piece in multi-selection mode.
  ///
  /// If the piece is already selected, it will be deselected. Otherwise, it will be selected.
  /// If no pieces remain selected after the operation, multi-selection mode is exited.
  void _onPieceSelected(MusicPiece piece) {
    setState(() {
      if (_selectedPieceIds.contains(piece.id)) {
        _selectedPieceIds.remove(piece.id); // Deselect the piece if already selected.
      } else {
        _selectedPieceIds.add(piece.id); // Select the piece if not already selected.
      }

      if (_selectedPieceIds.isEmpty) {
        _isMultiSelectMode = false; // Exit multi-select mode if no pieces are selected.
      }
    });
  }

  /// Initializes [SharedPreferences] and loads the saved sort option.
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _sortOption = _prefs.getString('sortOption') ?? 'alphabetical_asc'; // Load saved sort option or default to alphabetical ascending.
  }

  /// Loads application settings, specifically the number of gallery columns.
  ///
  /// Determines a default number of columns based on the platform and loads
  /// the user's saved preference from SharedPreferences.
  Future<void> _loadSettings() async {
    AppLogger.log('LibraryScreen: _loadSettings called');
    int defaultColumns;
    // Set default column count based on the platform for optimal display.
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      defaultColumns = 4; // Default for web, macOS, and Linux.
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      defaultColumns = 6; // Default for Windows.
    } else {
      defaultColumns = 2; // Default for mobile platforms (Android, iOS).
    }
    // Retrieve the saved gallery column count, or use the platform-specific default.
    final loadedColumns = _prefs.getInt('galleryColumns') ?? defaultColumns;
    AppLogger.log('Loaded galleryColumns: $loadedColumns');
    if (mounted) {
      setState(() {
        _galleryColumns = loadedColumns; // Update the state with the loaded column count.
      });
    }
  }

  /// Loads initial data for the screen, including groups, music pieces, and settings.
  ///
  /// This function is called once when the screen initializes to populate the UI.
  Future<void> _loadInitialData() async {
    await _loadGroups(); // Load all available groups from the database.
    await _loadMusicPieces(); // Load all music pieces and apply initial filters/sorting.
    await _loadSettings(); // Load user-specific settings like gallery column count.
  }

  /// Loads all groups from the database and shared preferences.
  ///
  /// This method fetches all user-created groups from the database and
  /// loads the settings for the special "All" and "Ungrouped" groups from
  /// shared preferences. It then combines and sorts them for display.
  Future<void> _loadGroups() async {
    AppLogger.log('LibraryScreen: _loadGroups called');
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final allDbGroups = await _repository.getGroups();
      AppLogger.log('LibraryScreen: Loaded ${allDbGroups.length} groups from DB.');

      // Get stored settings for special groups, with default values
      final allGroupOrder = _prefs.getInt('all_group_order') ?? -2;
      final allGroupIsHidden = _prefs.getBool('all_group_isHidden') ?? true;
      final ungroupedGroupOrder = _prefs.getInt('ungrouped_group_order') ?? -1;
      final ungroupedGroupIsHidden = _prefs.getBool('ungrouped_group_isHidden') ?? false;

      final allGroup = Group(
        id: 'all_group',
        name: 'All',
        order: allGroupOrder,
        isHidden: allGroupIsHidden,
      );

      final ungroupedGroup = Group(
        id: 'ungrouped_group',
        name: 'Ungrouped',
        order: ungroupedGroupOrder,
        isHidden: ungroupedGroupIsHidden,
      );

      // Combine user-defined groups with the special groups
      List<Group> combinedGroups = [allGroup, ungroupedGroup, ...allDbGroups];

      combinedGroups.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });

      if (mounted) {
        setState(() {
          _groups = combinedGroups;
          AppLogger.log('LibraryScreen: All groups (including special): ${_groups.map((g) => '${g.name} (id: ${g.id}, order: ${g.order}, hidden: ${g.isHidden})').join(', ')}');
          if (_selectedGroupId != null && !_groups.any((g) => g.id == _selectedGroupId)) {
            _selectedGroupId = null;
          }
          _groupListKey = UniqueKey();
        });
      }
    } catch (e) {
      _errorMessage = 'Failed to load groups: $e';
      AppLogger.log('LibraryScreen: Error loading groups: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Loads all music pieces from the database and applies current filters and sorting.
  Future<void> _loadMusicPieces() async {
    if (mounted) {
      setState(() {
        _isLoading = true; // Set loading state to true.
        _errorMessage = null; // Clear any previous error messages.
      });
    }
    try {
      _allMusicPieces = await _repository.getMusicPieces(); // Fetch all music pieces from the repository.

      List<MusicPiece> currentPieces = _allMusicPieces; // Start with all pieces.

      if (_selectedGroupId != null && _selectedGroupId != 'all_group') {
        if (_selectedGroupId == 'ungrouped_group') {
          currentPieces = currentPieces.where((piece) => piece.groupIds.isEmpty).toList();
        } else {
          currentPieces = currentPieces.where((piece) => piece.groupIds.contains(_selectedGroupId)).toList(); // Filter by selected group if any.
        }
      }

      _musicPieces = _filterMusicPieces(currentPieces); // Apply search and filter options.
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load music pieces: $e'; // Set error message if loading fails.
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading state to false after operation completes.
        });
      }
    }
  }

    /// Filters and sorts a given list of [MusicPiece] objects based on
  /// the current search query, filter options, and sort option.
  List<MusicPiece> _filterMusicPieces(List<MusicPiece> pieces) {
    List<MusicPiece> filteredPieces = pieces.where((piece) {
      final lowerCaseSearchQuery = _searchQuery.toLowerCase();
      // Check if the piece matches the search query in title, artist/composer, or tags.
      final matchesSearch = piece.title.toLowerCase().contains(lowerCaseSearchQuery) ||
          piece.artistComposer.toLowerCase().contains(lowerCaseSearchQuery) ||
          piece.tagGroups.any((tg) => tg.tags.any((tag) => tag.toLowerCase().contains(lowerCaseSearchQuery))) ||
          piece.tags.any((t) => t.toLowerCase().contains(lowerCaseSearchQuery));

      // Check for title match from filter options.
      final titleMatch = _filterOptions['title'] == null ||
          piece.title.toLowerCase().contains(_filterOptions['title'].toLowerCase());
      // Check for artist/composer match from filter options.
      final artistComposerMatch = _filterOptions['artistComposer'] == null ||
          piece.artistComposer.toLowerCase().contains(_filterOptions['artistComposer'].toLowerCase());
      // Check for ordered tags match from filter options.
      final orderedTagsMatch = (_filterOptions['orderedTags'] == null || (_filterOptions['orderedTags'] as Map<String, List<String>>).isEmpty) ||
          (_filterOptions['orderedTags'] as Map<String, List<String>>).entries.every((entry) {
            final selectedTagSetName = entry.key;
            final selectedTags = entry.value;
            return piece.tagGroups.any((pieceTagGroup) =>
                pieceTagGroup.name == selectedTagSetName &&
                selectedTags.every((selectedTag) => pieceTagGroup.tags.contains(selectedTag)));
          });
      // Check for general tags match from filter options.
      final tagsMatch = _filterOptions['tags'] == null ||
          piece.tags.any((t) => t.toLowerCase().contains(_filterOptions['tags'].toLowerCase()));

      // Apply practice tracking filter.
      final practiceTrackingFilter = _filterOptions['practiceTracking'];
      bool practiceTrackingMatch = true;
      if (practiceTrackingFilter == 'enabled') {
        practiceTrackingMatch = piece.enablePracticeTracking;
      } else if (practiceTrackingFilter == 'disabled') {
        practiceTrackingMatch = !piece.enablePracticeTracking;
      }

      // Apply practice duration filter.
      final practiceDurationFilter = _filterOptions['practiceDuration'];
      bool practiceDurationMatch = true;
      if (practiceDurationFilter != null) {
        if (practiceDurationFilter == 'last7Days') {
          practiceDurationMatch = piece.lastPracticeTime != null &&
              DateTime.now().difference(piece.lastPracticeTime!).inDays <= 7;
        } else if (practiceDurationFilter == 'notIn30Days') {
          practiceDurationMatch = piece.lastPracticeTime != null &&
              DateTime.now().difference(piece.lastPracticeTime!).inDays > 30;
        } else if (practiceDurationFilter == 'neverPracticed') {
          practiceDurationMatch = piece.lastPracticeTime == null;
        }
      }

      // Combine all filter conditions.
      return matchesSearch && titleMatch && artistComposerMatch && orderedTagsMatch && tagsMatch && practiceTrackingMatch && practiceDurationMatch;
    }).toList();

    // Apply sorting based on the selected sort option.
    if (_sortOption == 'alphabetical_asc') {
      filteredPieces.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortOption == 'alphabetical_desc') {
      filteredPieces.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    } else if (_sortOption.startsWith('last_practiced')) {
      filteredPieces.sort((a, b) {
        // Prioritize pieces with practice tracking enabled.
        if (a.enablePracticeTracking && !b.enablePracticeTracking) return -1;
        if (!a.enablePracticeTracking && b.enablePracticeTracking) return 1;
        if (!a.enablePracticeTracking && !b.enablePracticeTracking) return 0;

        // Handle pieces that have never been practiced.
        final aNeverPracticed = a.lastPracticeTime == null;
        final bNeverPracticed = b.lastPracticeTime == null;
        if (aNeverPracticed && bNeverPracticed) return 0;

        // Sort by last practice time (ascending or descending).
        if (_sortOption == 'last_practiced_asc') {
          if (aNeverPracticed) return 1;
          if (bNeverPracticed) return -1;
          return a.lastPracticeTime!.compareTo(b.lastPracticeTime!);
        } else {
          if (aNeverPracticed) return 1;
          if (bNeverPracticed) return -1;
          return b.lastPracticeTime!.compareTo(a.lastPracticeTime!);
        }
      });
    }

    return filteredPieces;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final visibleGroups = LibraryUtils.getVisibleGroups(_groups);
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        // Track currently pressed keys for multi-selection with Shift key.
        if (event is KeyDownEvent) {
          _pressedKeys.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _pressedKeys.remove(event.logicalKey);
        }
      },
      child: Scaffold(
        appBar: LibraryAppBar(
          isMultiSelectMode: _isMultiSelectMode,
          searchQuery: _searchQuery,
          onSearchChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            _loadMusicPieces();
          },
          hasActiveFilters: _hasActiveFilters,
          filterOptions: _filterOptions,
          onFilterOptionsChanged: (newFilterOptions) {
            setState(() {
              _filterOptions = newFilterOptions;
            });
          },
          onApplyFilter: _loadMusicPieces,
          onClearFilter: () {
            setState(() {
              _filterOptions = {
                'orderedTags': <String, List<String>>{},
              };
            });
            _loadMusicPieces();
          },
          sortOption: _sortOption,
          onSortOptionChanged: (newSortOption) {
            setState(() {
              _sortOption = newSortOption;
            });
            _loadMusicPieces();
          },
          onToggleMultiSelectMode: _toggleMultiSelectMode,
          selectedPieceCount: _selectedPieceIds.length,
          onSelectAll: () {
            setState(() {
              final allPieceIds = _musicPieces.map((p) => p.id).toSet();
              if (_selectedPieceIds.length == allPieceIds.length) {
                _selectedPieceIds.clear();
              } else {
                _selectedPieceIds.addAll(allPieceIds);
              }
            });
          },
          repository: _repository,
          prefs: _prefs,
          onSettingsChanged: () async {
            await _loadGroups();
            await _loadMusicPieces();
            await _loadSettings();
          },
        ),
        body: LibraryBody(
          visibleGroups: visibleGroups,
          selectedGroupId: _selectedGroupId,
          allMusicPieces: _allMusicPieces,
          musicPieces: _musicPieces,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          galleryColumns: _galleryColumns,
          groupListKey: _groupListKey,
          pageController: _pageController,
          groupScrollController: _groupScrollController,
          isMultiSelectMode: _isMultiSelectMode,
          selectedPieceIds: _selectedPieceIds,
          pressedKeys: _pressedKeys,
          onPieceSelected: _onPieceSelected,
          onReloadData: () async {
            await _loadGroups();
            await _loadMusicPieces();
          },
          onToggleMultiSelectMode: _toggleMultiSelectMode,
          onGroupSelected: (groupId) {
            setState(() {
              _selectedGroupId = groupId;
              final index = _groups.indexWhere((g) => g.id == groupId);
              if (_pageController.hasClients && index != -1) {
                _pageController.jumpToPage(index);
              }
              _loadMusicPieces();
            });
          },
        ),
        // Display multi-select bottom app bar if in multi-select mode.
        bottomNavigationBar: _isMultiSelectMode
            ? LibraryBottomAppBar(
                isMultiSelectMode: _isMultiSelectMode,
                onDeleteSelectedPieces: () {
                  LibraryActions(repository: _repository, onReloadMusicPieces: _loadMusicPieces, onToggleMultiSelectMode: _toggleMultiSelectMode, allMusicPieces: _allMusicPieces).deleteSelectedPieces(context, _selectedPieceIds);
                },
                onModifyGroupOfSelectedPieces: () {
                  LibraryActions(repository: _repository, onReloadMusicPieces: _loadMusicPieces, onToggleMultiSelectMode: _toggleMultiSelectMode, allMusicPieces: _allMusicPieces).modifyGroupOfSelectedPieces(context, _selectedPieceIds, _groups);
                },
                isSelectionEmpty: _selectedPieceIds.isEmpty,
              )
            : null,
        // Floating action button for adding new music pieces.
        floatingActionButton: _isMultiSelectMode
            ? null // Hide FAB in multi-select mode.
            : FloatingActionButton(
                onPressed: () async {
                  // Navigate to AddEditPieceScreen to add a new piece.
                  final result = await Navigator.of(context).push<bool?>(
                    MaterialPageRoute(builder: (context) => AddEditPieceScreen(selectedGroupId: _selectedGroupId)),
                  );
                  if (result == true) {
                    // Reload data if a piece was successfully added/edited.
                    await _loadGroups();
                    await _loadMusicPieces();
                  }
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
