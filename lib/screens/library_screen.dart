import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repertoire/widgets/tag_group_filter_dialog.dart';
import 'package:flutter/foundation.dart';
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

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<MusicPiece> _allMusicPieces = [];
  List<MusicPiece> _musicPieces = []; // This will hold the filtered and sorted list
  String _searchQuery = '';
  Map<String, dynamic> _filterOptions = {};
  String _sortOption = 'alphabetical_asc'; // Default sort option
  List<Group> _groups = []; // Renamed from _allGroups for consistency
  String? _selectedGroupId; // To track the currently selected group
  late SharedPreferences _prefs;
  bool _isLoading = false;
  String? _errorMessage;
  int _galleryColumns = 1;
  Key _groupListKey = UniqueKey(); // New key for group list
  late PageController _pageController;
  late ScrollController _groupScrollController; // New scroll controller for group chips

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _groupScrollController = ScrollController(); // Initialize the scroll controller
    _initSharedPreferences();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _groupScrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortOption = _prefs.getString('sortOption') ?? 'alphabetical_asc';
    });
  }

  Future<void> _loadSettings() async {
    print('LibraryScreen: _loadSettings called');
    int defaultColumns;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      defaultColumns = 4; // Desktop and web builds (excluding Windows)
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      defaultColumns = 6; // Windows builds
    } else {
      defaultColumns = 2; // Mobile builds (Android, iOS)
    }
    final loadedColumns = _prefs.getInt('galleryColumns') ?? defaultColumns;
    print('Loaded galleryColumns: $loadedColumns');
    setState(() {
      _galleryColumns = loadedColumns;
    });
  }

  Future<void> _loadInitialData() async {
    await _loadGroups();
    await _loadMusicPieces();
    _loadSettings(); // Load settings after prefs are initialized
  }

  

  

  

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _repository.ensureDefaultGroupExists();
      final allGroups = await _repository.getGroups();
      _groups = allGroups.where((g) => !g.isDefault).toList();
      _groups.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });
      // If the currently selected group was deleted, reset to 'All'
      if (_selectedGroupId != null && !_groups.any((g) => g.id == _selectedGroupId)) {
        _selectedGroupId = null;
      }
      _groupListKey = UniqueKey(); // Update key to force rebuild
    } catch (e) {
      _errorMessage = 'Failed to load groups: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMusicPieces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Always load all pieces first
      _allMusicPieces = await _repository.getMusicPieces();

      // Then filter based on selected group and search/filter options
      List<MusicPiece> currentPieces = _allMusicPieces;

      if (_selectedGroupId != null) {
        currentPieces = currentPieces.where((piece) => piece.groupIds.contains(_selectedGroupId)).toList();
      }

      _musicPieces = _filterMusicPieces(currentPieces);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load music pieces: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MusicPiece> _filterMusicPieces(List<MusicPiece> pieces) {
    List<MusicPiece> filteredPieces = pieces.where((piece) {
      final lowerCaseSearchQuery = _searchQuery.toLowerCase();
      final matchesSearch = piece.title.toLowerCase().contains(lowerCaseSearchQuery) ||
          piece.artistComposer.toLowerCase().contains(lowerCaseSearchQuery) ||
          piece.tagGroups.any((tg) => tg.tags.any((tag) => tag.toLowerCase().contains(lowerCaseSearchQuery))) ||
          piece.tags.any((t) => t.toLowerCase().contains(lowerCaseSearchQuery));

      final titleMatch = _filterOptions['title'] == null ||
          piece.title.toLowerCase().contains(_filterOptions['title'].toLowerCase());
      final artistComposerMatch = _filterOptions['artistComposer'] == null ||
          piece.artistComposer.toLowerCase().contains(_filterOptions['artistComposer'].toLowerCase());
      final orderedTagsMatch = (_filterOptions['orderedTags'] == null || (_filterOptions['orderedTags'] as Map<String, List<String>>).isEmpty) ||
          (_filterOptions['orderedTags'] as Map<String, List<String>>).entries.every((entry) {
            final selectedTagSetName = entry.key;
            final selectedTags = entry.value;
            return piece.tagGroups.any((pieceTagGroup) =>
                pieceTagGroup.name == selectedTagSetName &&
                selectedTags.every((selectedTag) => pieceTagGroup.tags.contains(selectedTag)));
          });
      final tagsMatch = _filterOptions['tags'] == null ||
          piece.tags.any((t) => t.toLowerCase().contains(_filterOptions['tags'].toLowerCase()));

      final practiceTrackingFilter = _filterOptions['practiceTracking'];
      bool practiceTrackingMatch = true;
      if (practiceTrackingFilter == 'enabled') {
        practiceTrackingMatch = piece.enablePracticeTracking;
      } else if (practiceTrackingFilter == 'disabled') {
        practiceTrackingMatch = !piece.enablePracticeTracking;
      }

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

      return matchesSearch && titleMatch && artistComposerMatch && orderedTagsMatch && tagsMatch && practiceTrackingMatch && practiceDurationMatch;
    }).toList();

    // Apply sorting based on _sortOption
    if (_sortOption == 'alphabetical_asc') {
      filteredPieces.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortOption == 'alphabetical_desc') {
      filteredPieces.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    } else if (_sortOption.startsWith('last_practiced')) {
      filteredPieces.sort((a, b) {
        // Handle practice tracking enabled/disabled
        if (a.enablePracticeTracking && !b.enablePracticeTracking) return -1;
        if (!a.enablePracticeTracking && b.enablePracticeTracking) return 1;
        if (!a.enablePracticeTracking && !b.enablePracticeTracking) return 0;

        // Handle never practiced
        final aNeverPracticed = a.lastPracticeTime == null;
        final bNeverPracticed = b.lastPracticeTime == null;
        if (aNeverPracticed && !bNeverPracticed) return 1;
        if (!aNeverPracticed && bNeverPracticed) return -1;
        if (aNeverPracticed && bNeverPracticed) return 0;

        // Sort by timestamp
        if (_sortOption == 'last_practiced_asc') {
          return a.lastPracticeTime!.compareTo(b.lastPracticeTime!);
        } else {
          return b.lastPracticeTime!.compareTo(a.lastPracticeTime!);
        }
      });
    }

    return filteredPieces;
  }

  double _calculateScrollOffset(int index) {
    // Assuming each chip has a fixed width for simplicity, or calculate dynamically
    // This is a simplified calculation. You might need to adjust based on actual chip sizes and spacing.
    // 4.0 (left padding) + 4.0 (right padding) + chip width
    // For "All" chip (index 0)
    double offset = 0.0;
    if (index == 0) {
      offset = 0.0; // "All" chip is at the beginning
    } else {
      // Calculate offset for other chips
      // Assuming average chip width + padding + spacing
      // This is a rough estimate. For precise calculation, you'd need to measure widget sizes.
      // For now, let's assume a fixed width per chip for calculation.
      // A more robust solution would involve using GlobalKey to get the render box of each chip.
      const double chipWidth = 100.0; // Approximate width of a chip
      const double paddingAndSpacing = 8.0; // 4.0 left + 4.0 right padding + 8.0 spacing
      offset = (index * (chipWidth + paddingAndSpacing));
    }

    // Ensure the offset doesn't exceed the max scroll extent
    if (_groupScrollController.hasClients) {
      return offset.clamp(0.0, _groupScrollController.position.maxScrollExtent);
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    print('LibraryScreen: Building with _galleryColumns: $_galleryColumns');
    return Scaffold(
      appBar: AppBar(
        title: TextField(
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
            _loadMusicPieces(); // Trigger search on every change
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter Options'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Title'),
                          initialValue: _filterOptions['title'],
                          onChanged: (value) => _filterOptions['title'] = value,
                        ),
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
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadMusicPieces();
                      },
                      child: const Text('Apply Filter'),
                    ),
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
          
          IconButton(
            icon: const Icon(Icons.settings), // Settings button
            onPressed: () async {
              final bool? changesMade = await Navigator.of(context).push<bool?>(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (changesMade == true) {
                _loadGroups();
                _loadMusicPieces();
                _loadSettings();
                setState(() {}); // Force rebuild
              }
            },
          ),
          
        ],
      ),
      body: Column(
        children: [
          // Group Toggling Bar (now controlled by PageView)
          if (_groups.isNotEmpty)
            SingleChildScrollView(
              key: _groupListKey, // Use the new key
              controller: _groupScrollController, // Attach the scroll controller
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Padding(
                    key: const ValueKey('all_groups_chip'),
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text('All (${_allMusicPieces.length})'),
                      selected: _selectedGroupId == null,
                      onSelected: (selected) {
                        if (selected) {
                          _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.ease);
                        }
                      },
                      showCheckmark: false,
                    ),
                  ),
                  ..._groups.where((g) => !g.isDefault).map((group) {
                    final pieceCount = _allMusicPieces.where((piece) => piece.groupIds.contains(group.id)).length;
                    return Padding(
                      key: ValueKey(group.id),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text('${group.name} ($pieceCount)'),
                        selected: _selectedGroupId == group.id,
                        onSelected: (selected) {
                          if (selected) {
                            final index = _groups.indexOf(group) + 1;
                            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.ease);
                          }
                        },
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _groups.length + 1, // +1 for "All" group
              onPageChanged: (index) {
                setState(() {
                  if (index == 0) {
                    _selectedGroupId = null; // "All" group
                  } else {
                    _selectedGroupId = _groups[index - 1].id;
                  }
                });

                // Scroll the selected chip into view
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
                  // Determine the group ID for the current page
                  String? currentPageGroupId;
                  if (pageIndex == 0) {
                    currentPageGroupId = null; // "All" group
                  } else {
                    currentPageGroupId = _groups[pageIndex - 1].id;
                  }

                  // Filter music pieces for the current page
                  final musicPiecesForPage = _allMusicPieces.where((piece) {
                    if (currentPageGroupId == null) {
                      return true; // Show all pieces for "All" group
                    } else {
                      return piece.groupIds.contains(currentPageGroupId);
                    }
                  }).toList();

                  // Apply search and filter options to the current page's pieces
                  final filteredAndSortedPieces = _filterMusicPieces(musicPiecesForPage);

                  if (filteredAndSortedPieces.isEmpty) {
                    return const Center(child: Text('No music pieces found in this group.'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await _loadGroups();
                      await _loadMusicPieces();
                    },
                    child: GridView.builder(
                      key: ValueKey('gallery_page_$currentPageGroupId'), // Force rebuild when group changes
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _galleryColumns,
                        crossAxisSpacing: 2.0,
                        mainAxisSpacing: 4.0,
                        childAspectRatio: 1.0, // Adjusted for square items
                      ),
                      itemCount: filteredAndSortedPieces.length,
                      itemBuilder: (context, index) {
                        return MusicPieceCard(
                          piece: filteredAndSortedPieces[index],
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PieceDetailScreen(musicPiece: filteredAndSortedPieces[index]),
                              ),
                            );
                            _loadMusicPieces(); // Reload data after returning from detail screen
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool?>(
            MaterialPageRoute(builder: (context) => AddEditPieceScreen(selectedGroupId: _selectedGroupId)),
          );
          if (result == true) {
            // Reload data if a piece was added/edited
            _loadGroups();
            _loadMusicPieces();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
