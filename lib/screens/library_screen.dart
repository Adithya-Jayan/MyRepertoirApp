import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repertoire/widgets/tag_group_filter_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/music_piece_repository.dart';
import '../models/group.dart'; // Import Group model
import '../models/music_piece.dart';

import './add_edit_piece_screen.dart';
import './music_piece_card.dart';
import './piece_detail_screen.dart';
import './settings_screen.dart';
import './tag_management_screen.dart';
import './personalization_settings_screen.dart';

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
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    // Initialize the PageController for managing page views.
    _pageController = PageController();
    // Initialize the ScrollController for the horizontal group chips.
    _groupScrollController = ScrollController();
    // Asynchronously initialize SharedPreferences.
    _initSharedPreferences();
    // Load initial data for the screen (groups, music pieces, settings).
    _loadInitialData();
    // Request focus for the keyboard listener to capture key events.
    _focusNode.requestFocus();
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
    setState(() {
      _sortOption = _prefs.getString('sortOption') ?? 'alphabetical_asc'; // Load saved sort option or default to alphabetical ascending.
    });
  }

  /// Loads application settings, specifically the number of gallery columns.
  ///
  /// Determines a default number of columns based on the platform and loads
  /// the user's saved preference from SharedPreferences.
  Future<void> _loadSettings() async {
    print('LibraryScreen: _loadSettings called');
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
    print('Loaded galleryColumns: $loadedColumns');
    setState(() {
      _galleryColumns = loadedColumns; // Update the state with the loaded column count.
    });
  }

  /// Loads initial data for the screen, including groups, music pieces, and settings.
  ///
  /// This function is called once when the screen initializes to populate the UI.
  Future<void> _loadInitialData() async {
    await _loadGroups(); // Load all available groups from the database.
    await _loadMusicPieces(); // Load all music pieces and apply initial filters/sorting.
    _loadSettings(); // Load user-specific settings like gallery column count.
  }

  /// Loads all groups from the database and shared preferences.
  ///
  /// This method fetches all user-created groups from the database and
  /// loads the settings for the special "All" and "Ungrouped" groups from
  /// shared preferences. It then combines and sorts them for display.
  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final allDbGroups = await _repository.getGroups();

      // Get stored settings for special groups, with default values
      final allGroupOrder = prefs.getInt('all_group_order') ?? -2;
      final allGroupIsHidden = prefs.getBool('all_group_isHidden') ?? false;
      final ungroupedGroupOrder = prefs.getInt('ungrouped_group_order') ?? -1;
      final ungroupedGroupIsHidden = prefs.getBool('ungrouped_group_isHidden') ?? false;

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

      setState(() {
        _groups = combinedGroups;
        if (_selectedGroupId != null && !_groups.any((g) => g.id == _selectedGroupId)) {
          _selectedGroupId = null;
        }
        _groupListKey = UniqueKey();
      });
    } catch (e) {
      _errorMessage = 'Failed to load groups: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Returns a list of groups that should be visible in the UI.
  ///
  /// If there are no user-created groups, this method returns an empty list.
  /// Otherwise, it returns all groups that are not hidden.
  List<Group> _getVisibleGroups() {
    final userGroups = _groups.where((g) => g.id != 'all_group' && g.id != 'ungrouped_group').toList();
    if (userGroups.isEmpty) {
      return [];
    }
    return _groups.where((g) => !g.isHidden).toList();
  }

  /// Loads all music pieces from the database and applies current filters and sorting.
  Future<void> _loadMusicPieces() async {
    setState(() {
      _isLoading = true; // Set loading state to true.
      _errorMessage = null; // Clear any previous error messages.
    });
    try {
      _allMusicPieces = await _repository.getMusicPieces(); // Fetch all music pieces from the repository.

      List<MusicPiece> currentPieces = _allMusicPieces; // Start with all pieces.

      if (_selectedGroupId != null) {
        currentPieces = currentPieces.where((piece) => piece.groupIds.contains(_selectedGroupId)).toList(); // Filter by selected group if any.
      }

      _musicPieces = _filterMusicPieces(currentPieces); // Apply search and filter options.
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load music pieces: $e'; // Set error message if loading fails.
      });
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false after operation completes.
      });
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
        if (aNeverPracticed && !bNeverPracticed) return 1;
        if (!aNeverPracticed && bNeverPracticed) return -1;
        if (aNeverPracticed && bNeverPracticed) return 0;

        // Sort by last practice time (ascending or descending).
        if (_sortOption == 'last_practiced_asc') {
          return a.lastPracticeTime!.compareTo(b.lastPracticeTime!);
        } else {
          return b.lastPracticeTime!.compareTo(a.lastPracticeTime!);
        }
      });
    }

    return filteredPieces;
  }

  /// Calculates the scroll offset for a given group chip index.
  ///
  /// This is used to programmatically scroll the horizontal list of group chips
  /// into view when a different group page is selected in the PageView.
  double _calculateScrollOffset(int index) {
    // This is a simplified calculation. For precise calculation, you'd need to measure widget sizes.
    // A more robust solution would involve using GlobalKey to get the render box of each chip.
    const double chipWidth = 100.0; // Approximate width of a chip.
    const double paddingAndSpacing = 8.0; // Combined horizontal padding and spacing between chips.
    double offset = (index * (chipWidth + paddingAndSpacing));

    // Ensure the calculated offset does not exceed the maximum scroll extent
    // of the SingleChildScrollView, preventing over-scrolling.
    if (_groupScrollController.hasClients) {
      return offset.clamp(0.0, _groupScrollController.position.maxScrollExtent);
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final visibleGroups = _getVisibleGroups();
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        // Track currently pressed keys for multi-selection with Shift key.
        if (event is RawKeyDownEvent) {
          _pressedKeys.add(event.logicalKey);
        } else if (event is RawKeyUpEvent) {
          _pressedKeys.remove(event.logicalKey);
        }
      },
      child: Scaffold(
        // Dynamically switch AppBar based on multi-selection mode.
        appBar: _isMultiSelectMode ? _buildMultiSelectAppBar() : _buildDefaultAppBar(),
        body: Column(
          children: [
          // Group Toggling Bar (horizontal scrollable chips).
          if (visibleGroups.isNotEmpty)
            SingleChildScrollView(
              key: _groupListKey, // Use the new key to force rebuild of the group list.
              controller: _groupScrollController, // Attach the scroll controller for horizontal scrolling.
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: visibleGroups.map((group) {
                  final isSelected = _selectedGroupId == group.id || (_selectedGroupId == null && group.id == 'all_group');
                  int pieceCount = 0;
                  if (group.id == 'all_group') {
                    pieceCount = _allMusicPieces.length;
                  } else if (group.id == 'ungrouped_group') {
                    pieceCount = _allMusicPieces.where((p) => p.groupIds.isEmpty).length;
                  } else {
                    pieceCount = _allMusicPieces.where((p) => p.groupIds.contains(group.id)).length;
                  }

                  return Padding(
                    key: ValueKey(group.id),
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text('${group.name} ($pieceCount)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          final index = _groups.indexOf(group);
                          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.ease);
                        }
                      },
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const SizedBox.shrink(), // Hide the group bar if no groups are available.
          Expanded(
            // PageView to display music pieces for each selected group.
            child: PageView.builder(
              controller: _pageController,
              itemCount: visibleGroups.isEmpty ? 1 : visibleGroups.length,
              onPageChanged: (index) {
                setState(() {
                  if (visibleGroups.isEmpty) {
                    _selectedGroupId = null;
                  } else {
                    _selectedGroupId = visibleGroups[index].id;
                  }
                });

                // Scroll the selected group chip into view.
                _groupScrollController.animateTo(
                  _calculateScrollOffset(index),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              },
              itemBuilder: (context, pageIndex) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (_errorMessage != null) {
                  return Center(child: Text(_errorMessage!));
                } else {
                  // Determine the group ID for the current page.
                  String? currentPageGroupId;
                  if (visibleGroups.isNotEmpty) {
                    currentPageGroupId = visibleGroups[pageIndex].id;
                  }

                  // Filter music pieces for the current page's group.
                  final musicPiecesForPage = _allMusicPieces.where((piece) {
                    if (currentPageGroupId == null || currentPageGroupId == 'all_group') {
                      return true; // Show all pieces for "All" group.
                    } else if (currentPageGroupId == 'ungrouped_group') {
                      return piece.groupIds.isEmpty; // Show pieces with no group
                    } else {
                      return piece.groupIds.contains(currentPageGroupId);
                    }
                  }).toList();

                  // Apply search and filter options to the current page's pieces.
                  final filteredAndSortedPieces = _filterMusicPieces(musicPiecesForPage);

                  if (filteredAndSortedPieces.isEmpty) {
                    return const Center(child: Text('No music pieces found in this group.'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await _loadGroups(); // Reload groups on refresh.
                      await _loadMusicPieces(); // Reload music pieces on refresh.
                    },
                    child: GridView.builder(
                      key: ValueKey('gallery_page_$currentPageGroupId'), // Force rebuild when group changes.
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _galleryColumns, // Number of columns in the grid.
                        crossAxisSpacing: 2.0,
                        mainAxisSpacing: 4.0,
                        childAspectRatio: 1.0, // Aspect ratio for each grid item (square).
                      ),
                      itemCount: filteredAndSortedPieces.length,
                      itemBuilder: (context, index) {
                        final piece = filteredAndSortedPieces[index];
                        final isSelected = _selectedPieceIds.contains(piece.id);
                        return MusicPieceCard(
                          piece: piece,
                          isSelected: isSelected,
                          onTap: () async {
                            // Check if Shift key is pressed for multi-selection.
                            final isShiftPressed = _pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
                                _pressedKeys.contains(LogicalKeyboardKey.shiftRight);

                            if (isShiftPressed) {
                              if (!_isMultiSelectMode) {
                                _toggleMultiSelectMode(); // Enter multi-select mode if not already in it.
                              }
                              _onPieceSelected(piece); // Select/deselect the piece.
                            } else if (_isMultiSelectMode) {
                              _onPieceSelected(piece); // Select/deselect the piece in multi-select mode.
                            } else {
                              // Navigate to PieceDetailScreen in single-selection mode.
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PieceDetailScreen(musicPiece: piece),
                                ),
                              );
                              await _loadMusicPieces(); // Reload data after returning from detail screen.
                            }
                          },
                          onLongPress: () {
                            // Enter multi-select mode on long press and select the piece.
                            if (!_isMultiSelectMode) {
                              _toggleMultiSelectMode();
                            }
                            _onPieceSelected(piece);
                          },
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      // Display multi-select bottom app bar if in multi-select mode.
      bottomNavigationBar: _isMultiSelectMode ? _buildMultiSelectBottomAppBar() : null,
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
    )
    );
  }

  /// Builds the default AppBar for the LibraryScreen.
  /// Includes a search bar, filter button, sort button, and settings button.
  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: TextField(
        // Search input field for filtering music pieces.
        decoration: InputDecoration(
          hintText: 'Search music pieces...',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _loadMusicPieces(); // Trigger search on every change.
        },
      ),
      actions: [
        Container(
          decoration: _hasActiveFilters
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Highlight background
                  borderRadius: BorderRadius.circular(8.0), // Optional: rounded corners
                )
              : null,
          child: IconButton(
            icon: const Icon(Icons.filter_list), // Icon color will be default now
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter Options'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Text field for filtering by title.
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Title'),
                          initialValue: _filterOptions['title'],
                          onChanged: (value) => _filterOptions['title'] = value,
                        ),
                        // Button to open tag group filter dialog.
                        ElevatedButton(
                          onPressed: () async {
                            final availableTags = await _repository.getAllUniqueTagGroups();
                            final selectedTags = await showDialog<Map<String, List<String>>>(
                              context: context,
                              builder: (context) => TagGroupFilterDialog(
                                availableTags: availableTags,
                                initialSelectedTags: _filterOptions['orderedTags'] ?? {},
                              ),
                            );

                            if (selectedTags != null) {
                              setState(() {
                                _filterOptions['orderedTags'] = selectedTags;
                              });
                            }
                          },
                          child: const Text('Select Ordered Tags'),
                        ),
                        
                        // Dropdown for practice tracking filter.
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Practice Tracking'),
                          value: _filterOptions['practiceTracking'],
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'enabled', child: Text('Enabled')),
                            DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterOptions['practiceTracking'] = value;
                            });
                          },
                        ),
                        // Dropdown for practice duration filter.
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Practice Duration'),
                          value: _filterOptions['practiceDuration'],
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Any')),
                            DropdownMenuItem(value: 'last7Days', child: Text('Practiced in last 7 days')),
                            DropdownMenuItem(value: 'notIn30Days', child: Text('Not practiced in 30 days')),
                            DropdownMenuItem(value: 'neverPracticed', child: Text('Never practiced')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterOptions['practiceDuration'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    // Button to apply filters.
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadMusicPieces();
                      },
                      child: const Text('Apply Filter'),
                    ),
                    // Button to clear all filters.
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterOptions = {
                            'orderedTags': <String, List<String>>{},
                          };
                        });
                        Navigator.pop(context);
                        _loadMusicPieces();
                      },
                      child: const Text('Clear Filter'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Sort button to open the sort options dialog.
        IconButton(
          icon: const Icon(Icons.swap_vert),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sort Options'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Option for alphabetical sorting.
                    ListTile(
                      title: const Text('Alphabetical'),
                      trailing: _sortOption.startsWith('alphabetical') ? (_sortOption.endsWith('asc') ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward)) : null,
                      onTap: () {
                        setState(() {
                          _sortOption = _sortOption == 'alphabetical_asc' ? 'alphabetical_desc' : 'alphabetical_asc';
                          _prefs.setString('sortOption', _sortOption);
                        });
                        _loadMusicPieces();
                        Navigator.pop(context);
                      },
                    ),
                    // Option for sorting by last practiced date.
                    ListTile(
                      title: const Text('Last Practiced'),
                      trailing: _sortOption.startsWith('last_practiced') ? (_sortOption.endsWith('asc') ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward)) : null,
                      onTap: () {
                        setState(() {
                          _sortOption = _sortOption == 'last_practiced_asc' ? 'last_practiced_desc' : 'last_practiced_asc';
                          _prefs.setString('sortOption', _sortOption);
                        });
                        _loadMusicPieces();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Settings button to navigate to the SettingsScreen.
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () async {
            // Navigate to SettingsScreen and wait for result.
            final bool? changesMade = await Navigator.of(context).push<bool?>(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            // If changes were made in settings, reload data and settings.
            if (changesMade == true) {
              await _loadGroups();
              await _loadMusicPieces();
              await _loadSettings();
            }
          },
        ),
        
      ],
    );
  }

  /// Builds the AppBar for multi-selection mode.
  ///
  /// Displays the number of selected items and provides a close button
  /// to exit multi-selection mode, and a select all/deselect all button.
  AppBar _buildMultiSelectAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleMultiSelectMode, // Exit multi-select mode when close button is pressed.
      ),
      title: Text('${_selectedPieceIds.length} selected'), // Display the count of currently selected music pieces.
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () {
            setState(() {
              final allPieceIds = _musicPieces.map((p) => p.id).toSet();
              // If all pieces are already selected, clear the selection; otherwise, select all pieces.
              if (_selectedPieceIds.length == allPieceIds.length) {
                _selectedPieceIds.clear();
              } else {
                _selectedPieceIds.addAll(allPieceIds);
              }
            });
          },
        ),
      ],
    );
  }

  /// Builds the BottomAppBar for multi-selection mode.
  ///
  /// Provides options to delete or modify groups of selected music pieces.
  Widget _buildMultiSelectBottomAppBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Button to delete selected music pieces.
          TextButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            onPressed: _selectedPieceIds.isEmpty ? null : _deleteSelectedPieces, // Disabled if no pieces are selected.
          ),
          // Button to modify group membership of selected music pieces.
          TextButton.icon(
            icon: const Icon(Icons.group_work),
            label: const Text('Modify Group'),
            onPressed: _selectedPieceIds.isEmpty ? null : _modifyGroupOfSelectedPieces, // Disabled if no pieces are selected.
          ),
        ],
      ),
    );
  }

  /// Deletes all currently selected music pieces after user confirmation.
  Future<void> _deleteSelectedPieces() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete ${_selectedPieceIds.length} selected item(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteMusicPieces(_selectedPieceIds.toList()); // Delete the selected music pieces from the database.
        _toggleMultiSelectMode(); // Exit multi-select mode after deletion.
        _loadMusicPieces(); // Reload music pieces to update the UI.
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting pieces: $e')),
        );
      }
    }
  }

  Future<void> _modifyGroupOfSelectedPieces() async {
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
              final currentSelectedPiecesInDialog = _allMusicPieces.where((p) => _selectedPieceIds.contains(p.id)).toList();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _groups.where((group) => group.id != 'all_group' && group.id != 'ungrouped_group').map((group) {
                    // Determine initial state
                    final isSelectedInAllInitial = currentSelectedPiecesInDialog.every((p) => p.groupIds.contains(group.id));
                    final isSelectedInSomeInitial = currentSelectedPiecesInDialog.any((p) => p.groupIds.contains(group.id)) && !isSelectedInAllInitial;

                    print('--- Group Debug ---');
                    print('Group: ${group.name} (ID: ${group.id})');
                    print('  isSelectedInAllInitial: $isSelectedInAllInitial');
                    print('  isSelectedInSomeInitial: $isSelectedInSomeInitial');

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
                    print('  Calculated checkboxValue: $checkboxValue');

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
                          print('  Pending change for ${group.name}: ${pendingGroupChanges[group.id]}');
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
                    await _repository.updateGroupMembershipForPieces(
                      _selectedPieceIds.toList(),
                      entry.key,
                      entry.value!,
                    );
                  }
                }
                await _loadMusicPieces(); // Refresh the data after applying changes
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    _toggleMultiSelectMode(); // Exit multi-select mode after modification
  }
}
