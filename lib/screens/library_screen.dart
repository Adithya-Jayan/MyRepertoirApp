import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/music_piece_repository.dart';
import '../models/group.dart'; // Import Group model
import '../models/music_piece.dart';
import '../services/file_scanner_service.dart';
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
  List<MusicPiece> _musicPieces = []; // Filtered list for display
  List<MusicPiece> _allMusicPieces = []; // All pieces for accurate counts
  List<Group> _groups = [];
  String? _selectedGroupId; // Null means "All"
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  Map<String, dynamic> _filterOptions = {};

  int _galleryColumns = 1;
  bool _isInitialLoadComplete = false; // New flag
  Key _groupListKey = UniqueKey(); // New key for group list

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoadComplete) {
      _isInitialLoadComplete = true;
    } else {
      // Reload data when returning to this screen
      _loadInitialData();
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    print('LibraryScreen: _loadSettings called');
    final prefs = await SharedPreferences.getInstance();
    final loadedColumns = prefs.getInt('galleryColumns') ?? 1;
    print('Loaded galleryColumns: $loadedColumns');
    setState(() {
      _galleryColumns = loadedColumns;
    });
  }

  Future<void> _loadInitialData() async {
    await _loadGroups();
    await _loadMusicPieces();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _repository.ensureDefaultGroupExists();
      final allGroups = await _repository.getGroups();
      final filteredGroups = allGroups.where((g) => !g.isDefault).toList();
      filteredGroups.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });
      setState(() {
        _groups = List.from(filteredGroups); // Create a new list instance
        print('LibraryScreen: _groups updated to: $_groups');
        // If the currently selected group was deleted, reset to 'All'
        if (_selectedGroupId != null && !_groups.any((g) => g.id == _selectedGroupId)) {
          _selectedGroupId = null;
        }
        _groupListKey = UniqueKey(); // Update key to force rebuild
        print('LibraryScreen: _groupListKey updated to: $_groupListKey');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load groups: $e';
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
      List<MusicPiece> filteredPieces = _allMusicPieces;

      if (_selectedGroupId != null) {
        filteredPieces = filteredPieces.where((piece) => piece.groupIds.contains(_selectedGroupId)).toList();
      }

      setState(() {
        _musicPieces = _filterMusicPieces(filteredPieces);
      });
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
          piece.orderedTags.any((ot) => ot.tags.any((tag) => tag.toLowerCase().contains(lowerCaseSearchQuery))) ||
          piece.tags.any((t) => t.toLowerCase().contains(lowerCaseSearchQuery));

      final titleMatch = _filterOptions['title'] == null ||
          piece.title.toLowerCase().contains(_filterOptions['title'].toLowerCase());
      final artistComposerMatch = _filterOptions['artistComposer'] == null ||
          piece.artistComposer.toLowerCase().contains(_filterOptions['artistComposer'].toLowerCase());
      final orderedTagsMatch = _filterOptions['orderedTags'] == null ||
          piece.orderedTags.any((ot) => ot.tags.any((tag) => tag.toLowerCase().contains(_filterOptions['orderedTags'].toLowerCase())));
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

    // Sort by last practiced, most recent at the bottom
    filteredPieces.sort((a, b) {
      if (a.lastPracticeTime == null && b.lastPracticeTime == null) return 0;
      if (a.lastPracticeTime == null) return 1; // Nulls go to the end
      if (b.lastPracticeTime == null) return -1; // Nulls go to the end
      return a.lastPracticeTime!.compareTo(b.lastPracticeTime!); // Ascending order
    });

    return filteredPieces;
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
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Artist/Composer'),
                          initialValue: _filterOptions['artistComposer'],
                          onChanged: (value) => _filterOptions['artistComposer'] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Ordered Tags'),
                          initialValue: _filterOptions['orderedTags'],
                          onChanged: (value) => _filterOptions['orderedTags'] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Tags'),
                          initialValue: _filterOptions['tags'],
                          onChanged: (value) => _filterOptions['tags'] = value,
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
                          _filterOptions = {};
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
          // Group Toggling Bar
          if (_groups.isNotEmpty)
            SingleChildScrollView(
              key: _groupListKey, // Use the new key
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
                          setState(() {
                            _selectedGroupId = null;
                          });
                          _loadMusicPieces();
                        }
                      },
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
                            setState(() {
                              _selectedGroupId = group.id;
                            });
                            _loadMusicPieces();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "No groups yet! Add one to organize your pieces :D",
                  style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _musicPieces.isEmpty
                        ? const Center(child: Text('No music pieces found. Add one!'))
                        : GridView.builder(
                            key: ValueKey(_galleryColumns), // Force rebuild when columns change
                            padding: const EdgeInsets.all(8.0),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _galleryColumns,
                              crossAxisSpacing: 4.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 1.0, // Adjusted for square items
                            ),
                            itemCount: _musicPieces.length,
                            itemBuilder: (context, index) {
                              return MusicPieceCard(
                                piece: _musicPieces[index],
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PieceDetailScreen(musicPiece: _musicPieces[index]),
                                    ),
                                  );
                                  _loadMusicPieces(); // Reload data after returning from detail screen
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool?>(
            MaterialPageRoute(builder: (context) => const AddEditPieceScreen()),
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
