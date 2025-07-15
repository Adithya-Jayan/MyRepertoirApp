import 'package:repertoire/models/tag_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:uuid/uuid.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/group.dart'; // Import Group model
import '../database/music_piece_repository.dart'; // Import repository
import 'package:file_picker/file_picker.dart';
import 'package:repertoire/widgets/media_display_widget.dart';
import '../services/media_storage_manager.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AddEditPieceScreen extends StatefulWidget {
  final MusicPiece? musicPiece;
  final String? selectedGroupId;

  const AddEditPieceScreen({super.key, this.musicPiece, this.selectedGroupId});

  @override
  State<AddEditPieceScreen> createState() => _AddEditPieceScreenState();
}

class _AddEditPieceScreenState extends State<AddEditPieceScreen> {
  final _formKey = GlobalKey<FormState>();
  late MusicPiece _musicPiece;
  List<Group> _availableGroups = [];
  Set<String> _selectedGroupIds = {};
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<String> _allTagGroupNames = []; // For tag group name suggestions

  final Map<String, TextEditingController> _tagInputControllers = {};

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Default', 'value': null},
    {'name': 'Red', 'value': Colors.red[300]!.value},
    {'name': 'Blue', 'value': Colors.blue[300]!.value},
    {'name': 'Green', 'value': Colors.green[300]!.value},
    {'name': 'Orange', 'value': Colors.orange[300]!.value},
    {'name': 'Purple', 'value': Colors.purple[300]!.value},
    {'name': 'Teal', 'value': Colors.teal[300]!.value},
    {'name': 'Indigo', 'value': Colors.indigo[300]!.value},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize _musicPiece. If editing an existing piece, create a deep copy
    // to avoid modifying the original object directly. Otherwise, create a new empty MusicPiece.
    _musicPiece = widget.musicPiece != null
        ? widget.musicPiece!.copyWith(
            mediaItems: widget.musicPiece!.mediaItems.map((item) => 
              MediaItem(
                id: item.id,
                type: item.type,
                pathOrUrl: item.pathOrUrl,
                title: item.title,
                thumbnailPath: item.thumbnailPath,
              )
            ).toList(),
            tagGroups: widget.musicPiece!.tagGroups.map((tagGroup) => 
              TagGroup(
                id: tagGroup.id,
                name: tagGroup.name,
                tags: List<String>.from(tagGroup.tags),
                color: tagGroup.color,
              )
            ).toList(),
            groupIds: List<String>.from(widget.musicPiece!.groupIds),
          )
        : MusicPiece(
            id: const Uuid().v4(), 
            title: '', 
            artistComposer: '', 
            mediaItems: [], 
            tagGroups: []
          );

    // Initialize _selectedGroupIds with the music piece's existing group IDs.
    _selectedGroupIds = Set<String>.from(_musicPiece.groupIds);
    // If adding a new piece and a selectedGroupId is provided, add it to the selected groups.
    if (widget.musicPiece == null && widget.selectedGroupId != null) {
      _selectedGroupIds.add(widget.selectedGroupId!);
    }
    
    _loadGroups(); // Load available groups for selection.
    _loadTagGroupNames(); // Load existing tag group names for autocomplete suggestions.

    // Initialize TextEditingControllers for each existing tag group's name field.
    for (var tagGroup in _musicPiece.tagGroups) {
      _tagInputControllers[tagGroup.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers to prevent memory leaks.
    _tagInputControllers.forEach((key, value) => value.dispose());
    super.dispose();
  }

  /// Loads all unique tag group names from the repository.
  ///
  /// This is used to provide suggestions for tag group names in the Autocomplete widget.
  Future<void> _loadTagGroupNames() async {
    final allUniqueTags = await _repository.getAllUniqueTagGroups(); // Fetch all unique tag groups from the repository.
    setState(() {
      _allTagGroupNames = allUniqueTags.keys.toList()..sort(); // Extract tag group names and sort them alphabetically.
    });
  }

  /// Retrieves all tags associated with a specific tag group name.
  ///
  /// This is used to provide suggestions for tags within a given tag group.
  Future<List<String>> _getAllTagsForTagGroup(String tagGroupName) async {
    final allUniqueTags = await _repository.getAllUniqueTagGroups(); // Fetch all unique tag groups.
    return allUniqueTags[tagGroupName]?.toList() ?? []; // Return tags for the specified group, or an empty list if not found.
  }

  /// Loads available groups from the repository.
  ///
  /// Excludes the default group from the list of available groups for selection.
  Future<void> _loadGroups() async {
    try {
      final groups = await _repository.getGroups(); // Fetch all groups from the repository.
      setState(() {
        _availableGroups = groups.where((group) => !group.isDefault).toList(); // Filter out the default group.
      });
    } catch (e) {
      // Log or display an error if groups fail to load.
      print('Error loading groups: $e');
    }
  }

  Future<void> _pickFile(MediaType type) async {
    FilePickerResult? result;
    if (type == MediaType.image) {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } else if (type == MediaType.pdf) {
      result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    } else if (type == MediaType.audio) {
      result = await FilePicker.platform.pickFiles(type: FileType.audio);
    } else if (type == MediaType.mediaLink) {
      // For video links, we don't pick a file, but rather expect a URL input.
      // This case will be handled by a simple text input.
      return;
    } else if (type == MediaType.markdown) {
      result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['md', 'txt']);
    }

    if (result != null && result.files.single.path != null) {
      try {
        final newPath = await MediaStorageManager.copyMediaToLocal(result.files.single.path!, _musicPiece.id, type);
        setState(() {
          _musicPiece.mediaItems.add(MediaItem(
            id: const Uuid().v4(),
            type: type,
            pathOrUrl: newPath,
          ));
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying file: $e'))
        );
      }
    }
  }

  /// Adds a new media item to the music piece.
  ///
  /// For media links and markdown, it directly adds an empty media item.
  /// For other media types (image, PDF, audio), it triggers the file picker.
  void _addMediaItem(MediaType type) {
    if (type == MediaType.mediaLink || type == MediaType.markdown) {
      setState(() {
        _musicPiece.mediaItems.add(MediaItem(
          id: const Uuid().v4(), // Generate a unique ID for the new media item.
          type: type,
          pathOrUrl: '', // Initialize with an empty path/URL.
        ));
      });
    } else {
      _pickFile(type); // Open file picker for other media types.
    }
  }

  /// Adds a new empty [TagGroup] to the current music piece.
  ///
  /// A new [TextEditingController] is also created for the new tag group's name field.
  void _addTagGroup() {
    setState(() {
      final newTagGroup = TagGroup(id: const Uuid().v4(), name: '', tags: []); // Create a new TagGroup with a unique ID.
      _musicPiece.tagGroups.add(newTagGroup); // Add the new tag group to the music piece.
      _tagInputControllers[newTagGroup.id] = TextEditingController(); // Create a new TextEditingController for the new tag group.
    });
  }

  /// Updates an existing [TagGroup] within the [_musicPiece]'s list of tag groups.
  ///
  /// This method ensures that the UI reflects the changes made to a tag group.
  void _updateTagGroupInMusicPiece(TagGroup oldTagGroup, TagGroup newTagGroup) {
    final List<TagGroup> updatedTagGroups = List.from(_musicPiece.tagGroups); // Create a mutable copy of the tag groups list.
    final int index = updatedTagGroups.indexWhere((element) => element.id == oldTagGroup.id); // Find the index of the old tag group.
    if (index != -1) {
      updatedTagGroups[index] = newTagGroup; // Replace the old tag group with the new one.
      setState(() {
        _musicPiece = _musicPiece.copyWith(tagGroups: updatedTagGroups); // Update the music piece with the modified tag groups list.
      });
    }
  }

  Future<void> _fetchAndSaveThumbnail(MediaItem item) async {
    if (item.type == MediaType.mediaLink && item.pathOrUrl.isNotEmpty) {
      try {
        final metadata = await MetadataFetch.extract(item.pathOrUrl);
        final thumbnailUrl = metadata?.image;

        if (thumbnailUrl != null) {
          final response = await http.get(Uri.parse(thumbnailUrl));
          final documentsDir = await getApplicationDocumentsDirectory();
          final thumbnailDir = Directory(p.join(documentsDir.path, _musicPiece.id, 'thumbnails'));
          if (!await thumbnailDir.exists()) {
            await thumbnailDir.create(recursive: true);
          }
          final thumbnailFile = File(p.join(thumbnailDir.path, '${item.id}.jpg'));
          await thumbnailFile.writeAsBytes(response.bodyBytes);
          item.thumbnailPath = thumbnailFile.path;
        }
      } catch (e) {
        print('Error fetching or saving thumbnail: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.musicPiece == null ? 'Add Piece' : 'Edit Piece'), // Dynamically set app bar title based on whether adding or editing.
        actions: [
          IconButton(
            icon: const Icon(Icons.save), // Save button.
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save(); // Save the current state of the form fields.

                for (var item in _musicPiece.mediaItems) {
                  await _fetchAndSaveThumbnail(item);
                }

                _musicPiece.groupIds = _selectedGroupIds.toList(); // Update the music piece's group IDs from selected groups.

                if (widget.musicPiece == null) {
                  await _repository.insertMusicPiece(_musicPiece); // Insert new music piece if adding.
                } else {
                  await _repository.updateMusicPiece(_musicPiece); // Update existing music piece if editing.
                }

                if (!mounted) return;
                Navigator.of(context).pop(true); // Return true to indicate success and pop the screen.
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key for validation and saving.
          child: ListView(
            children: [
              TextFormField(
                initialValue: _musicPiece.title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null, // Validator for title field.
                onSaved: (value) => _musicPiece.title = value!, // Save title to music piece object.
              ),
              TextFormField(
                initialValue: _musicPiece.artistComposer,
                decoration: const InputDecoration(labelText: 'Artist/Composer'),
                onSaved: (value) => _musicPiece.artistComposer = value!, // Save artist/composer to music piece object.
              ),
              // Add other core attributes here
              const SizedBox(height: 20),
              ExpansionTile(
                title: const Text('Groups'),
                initiallyExpanded: false,
                children: [
                  ..._availableGroups.map((group) {
                    return CheckboxListTile(
                      title: Text(group.name),
                      value: _selectedGroupIds.contains(group.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedGroupIds.add(group.id); // Add group to selected if checked.
                          } else {
                            _selectedGroupIds.remove(group.id); // Remove group from selected if unchecked.
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Tag Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _musicPiece.tagGroups.length,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final tagGroup = _musicPiece.tagGroups[index];
                  return _buildTagGroupSection(tagGroup, index); // Build UI for each tag group.
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final tagGroup = _musicPiece.tagGroups.removeAt(oldIndex); // Remove tag group from old position.
                    _musicPiece.tagGroups.insert(newIndex, tagGroup); // Insert tag group at new position.
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _musicPiece.mediaItems.length,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final item = _musicPiece.mediaItems[index];
                  return _buildMediaSection(item, index); // Build UI for each media item.
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _musicPiece.mediaItems.removeAt(oldIndex); // Remove media item from old position.
                    _musicPiece.mediaItems.insert(newIndex, item); // Insert media item at new position.
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.text_fields),
            label: 'Markdown Text',
            onTap: () => _addMediaItem(MediaType.markdown), // Add markdown media item.
          ),
          SpeedDialChild(
            child: const Icon(Icons.picture_as_pdf),
            label: 'PDF Sheet Music',
            onTap: () => _addMediaItem(MediaType.pdf), // Add PDF media item.
          ),
          SpeedDialChild(
            child: const Icon(Icons.image),
            label: 'Image',
            onTap: () => _addMediaItem(MediaType.image), // Add image media item.
          ),
          SpeedDialChild(
            child: const Icon(Icons.audiotrack),
            label: 'Audio Recording',
            onTap: () => _addMediaItem(MediaType.audio), // Add audio media item.
          ),
          SpeedDialChild(
            child: const Icon(Icons.video_library),
            label: 'Media Link',
            onTap: () => _addMediaItem(MediaType.mediaLink), // Add media link item.
          ),
          SpeedDialChild(
            child: const Icon(Icons.label),
            label: 'Add Tag Group',
            onTap: _addTagGroup, // Add new tag group.
          ),
        ],
      ),
    );
  }

  /// Builds a UI section for a single [TagGroup], allowing editing of its name, color, and tags.
  Widget _buildTagGroupSection(TagGroup tagGroup, int index) {
    // Ensure a TextEditingController exists for this tag group's name.
    _tagInputControllers.putIfAbsent(tagGroup.id, () => TextEditingController());
    _tagInputControllers[tagGroup.id]!.text = tagGroup.name;

    return Card(
      key: ValueKey(tagGroup.id), // Unique key for ReorderableListView.
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Autocomplete<String>(
                          initialValue: TextEditingValue(text: tagGroup.name),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<String>.empty();
                            }
                            // Provide tag group name suggestions based on user input.
                            return _allTagGroupNames.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            // Update the tag group name when a suggestion is selected.
                            _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(name: selection));
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(labelText: 'Tag Group Name'),
                              onChanged: (value) {
                                tagGroup.name = value; // Update the tag group name as text changes.
                              },
                              onFieldSubmitted: (value) {
                                // Add new tag group name to suggestions if it's unique.
                                if (value.isNotEmpty && !_allTagGroupNames.contains(value)) {
                                  _allTagGroupNames.add(value);
                                  _allTagGroupNames.sort();
                                }
                                _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(name: value));
                                onFieldSubmitted();
                              },
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete), // Button to delete the tag group.
                        onPressed: () {
                          setState(() {
                            _musicPiece.tagGroups.remove(tagGroup); // Remove the tag group from the music piece.
                            _tagInputControllers[tagGroup.id]?.dispose(); // Dispose its TextEditingController.
                            _tagInputControllers.remove(tagGroup.id);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Text('Color:'),
                      const SizedBox(width: 8.0),
                      DropdownButton<int?>(
                        value: tagGroup.color, // Current color of the tag group.
                        onChanged: (int? newColor) {
                          _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(color: newColor)); // Update tag group color.
                        },
                        items: _colorOptions.map((option) {
                          return DropdownMenuItem<int?>(
                            value: option['value'] as int?,
                            child: Row(
                              children: [
                                if (option['value'] != null)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: Color(option['value'] as int), // Display color swatch.
                                  ),
                                if (option['value'] != null) const SizedBox(width: 8),
                                Text(option['name'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: tagGroup.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          final updatedTags = List<String>.from(tagGroup.tags).where((t) => t != tag).toList(); // Remove tag from the list.
                          _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(tags: updatedTags)); // Update tag group with removed tag.
                        },
                      );
                    }).toList(),
                  ),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      // Provide tag suggestions based on the selected tag group.
                      return _getAllTagsForTagGroup(tagGroup.name).then((allTags) {
                        return allTags.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      });
                    },
                    onSelected: (String selection) {
                      if (!tagGroup.tags.contains(selection)) {
                        final updatedTags = List<String>.from(tagGroup.tags)..add(selection); // Add selected tag to the list.
                        _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(tags: updatedTags)); // Update tag group with new tag.
                      }
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Add new tag'),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            final tagsToAdd = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(); // Split input by comma to add multiple tags.
                            final updatedTags = List<String>.from(tagGroup.tags)..addAll(tagsToAdd); // Add new tags to the list.
                            _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(tags: updatedTags)); // Update tag group with new tags.
                          }
                          textEditingController.clear(); // Clear the text field after submission.
                          onFieldSubmitted();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.drag_handle), // Drag handle for reordering.
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(MediaItem item, int index) {
    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MediaDisplayWidget(
                    mediaItem: item,
                    onTitleChanged: (newTitle) {
                      // Update the item directly without calling setState
                      // This prevents the widget from rebuilding during editing
                      item.title = newTitle;
                    },
                    isEditable: true,
                  ),
                  if (item.type == MediaType.image || (item.type == MediaType.mediaLink && item.thumbnailPath != null))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Set as thumbnail'),
                        Switch(
                          value: _musicPiece.thumbnailPath == (item.type == MediaType.image ? item.pathOrUrl : item.thumbnailPath),
                          onChanged: (value) {
                            setState(() {
                              _musicPiece = _musicPiece.copyWith(
                                thumbnailPath: value ? (item.type == MediaType.image ? item.pathOrUrl : item.thumbnailPath) : null,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  if (item.type == MediaType.markdown)
                    TextFormField(
                      initialValue: item.pathOrUrl,
                      decoration: const InputDecoration(
                        labelText: 'Markdown Content', 
                        border: OutlineInputBorder()
                      ),
                      maxLines: 5,
                      onChanged: (value) => item.pathOrUrl = value,
                    )
                  else
                    TextFormField(
                      initialValue: item.pathOrUrl,
                      decoration: const InputDecoration(labelText: 'Path or URL'),
                      onChanged: (value) => item.pathOrUrl = value,
                    ),
                ],
              ),
            ),
            Column(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await MediaStorageManager.deleteLocalMediaFile(item.pathOrUrl);
                    setState(() {
                      _musicPiece.mediaItems.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



