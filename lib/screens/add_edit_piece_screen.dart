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
    _musicPiece = widget.musicPiece != null
        ? widget.musicPiece!.copyWith(mediaItems: List.from(widget.musicPiece!.mediaItems), tagGroups: List.from(widget.musicPiece!.tagGroups))
        : MusicPiece(id: const Uuid().v4(), title: '', artistComposer: '', mediaItems: [], tagGroups: []);

        _selectedGroupIds = Set<String>.from(_musicPiece.groupIds);
    if (widget.musicPiece == null && widget.selectedGroupId != null) {
      _selectedGroupIds.add(widget.selectedGroupId!);
    }
    _loadGroups();
    _loadTagGroupNames();

    // Initialize controllers for existing tag groups
    for (var tagGroup in _musicPiece.tagGroups) {
      _tagInputControllers[tagGroup.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tagInputControllers.forEach((key, value) => value.dispose());
    super.dispose();
  }

  Future<void> _loadTagGroupNames() async {
    final allUniqueTags = await _repository.getAllUniqueTagGroups(); // This method name needs to be updated to getAllUniqueTagGroups
    setState(() {
      _allTagGroupNames = allUniqueTags.keys.toList()..sort();
    });
  }

  Future<List<String>> _getAllTagsForTagGroup(String tagGroupName) async {
    final allUniqueTags = await _repository.getAllUniqueTagGroups();
    return allUniqueTags[tagGroupName]?.toList() ?? [];
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _repository.getGroups();
      setState(() {
        _availableGroups = groups.where((group) => !group.isDefault).toList(); // Exclude default group from selection
      });
    } catch (e) {
      // Handle error loading groups
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
      setState(() {
        _musicPiece.mediaItems.add(MediaItem(
          id: const Uuid().v4(),
          type: type,
          pathOrUrl: result!.files.single.path!,
        ));
      });
    }
  }

  void _addMediaItem(MediaType type) {
    if (type == MediaType.mediaLink || type == MediaType.markdown) {
      setState(() {
        _musicPiece.mediaItems.add(MediaItem(
          id: const Uuid().v4(),
          type: type,
          pathOrUrl: '',
        ));
      });
    } else {
      _pickFile(type);
    }
  }

  void _addTagGroup() {
    setState(() {
      final newTagGroup = TagGroup(id: const Uuid().v4(), name: '', tags: []);
      _musicPiece.tagGroups.add(newTagGroup);
      _tagInputControllers[newTagGroup.id] = TextEditingController();
    });
  }

  void _updateTagGroupInMusicPiece(TagGroup oldTagGroup, TagGroup newTagGroup) {
    final List<TagGroup> updatedTagGroups = List.from(_musicPiece.tagGroups);
    final int index = updatedTagGroups.indexWhere((element) => element.id == oldTagGroup.id);
    if (index != -1) {
      updatedTagGroups[index] = newTagGroup;
      setState(() {
        _musicPiece = _musicPiece.copyWith(tagGroups: updatedTagGroups);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.musicPiece == null ? 'Add Piece' : 'Edit Piece'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _musicPiece.groupIds = _selectedGroupIds.toList();

                if (widget.musicPiece == null) {
                  await _repository.insertMusicPiece(_musicPiece);
                } else {
                  await _repository.updateMusicPiece(_musicPiece);
                }

                Navigator.of(context).pop(true); // Return true to indicate success
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _musicPiece.title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                onSaved: (value) => _musicPiece.title = value!,
              ),
              TextFormField(
                initialValue: _musicPiece.artistComposer,
                decoration: const InputDecoration(labelText: 'Artist/Composer'),
                onSaved: (value) => _musicPiece.artistComposer = value!,
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
                            _selectedGroupIds.add(group.id);
                          } else {
                            _selectedGroupIds.remove(group.id);
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
                  return _buildTagGroupSection(tagGroup, index);
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final tagGroup = _musicPiece.tagGroups.removeAt(oldIndex);
                    _musicPiece.tagGroups.insert(newIndex, tagGroup);
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
                  return _buildMediaSection(item, index);
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _musicPiece.mediaItems.removeAt(oldIndex);
                    _musicPiece.mediaItems.insert(newIndex, item);
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
            onTap: () => _addMediaItem(MediaType.markdown),
          ),
          SpeedDialChild(
            child: const Icon(Icons.picture_as_pdf),
            label: 'PDF Sheet Music',
            onTap: () => _addMediaItem(MediaType.pdf),
          ),
          SpeedDialChild(
            child: const Icon(Icons.image),
            label: 'Image',
            onTap: () => _addMediaItem(MediaType.image),
          ),
          SpeedDialChild(
            child: const Icon(Icons.audiotrack),
            label: 'Audio Recording',
            onTap: () => _addMediaItem(MediaType.audio),
          ),
          SpeedDialChild(
            child: const Icon(Icons.video_library),
            label: 'Media Link',
            onTap: () => _addMediaItem(MediaType.mediaLink),
          ),
          SpeedDialChild(
            child: const Icon(Icons.label),
            label: 'Add Tag Group',
            onTap: _addTagGroup,
          ),
        ],
      ),
    );
  }

  Widget _buildTagGroupSection(TagGroup tagGroup, int index) {
    _tagInputControllers.putIfAbsent(tagGroup.id, () => TextEditingController());
    _tagInputControllers[tagGroup.id]!.text = tagGroup.name;

    return Card(
      key: ValueKey(tagGroup.id),
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
                            return _allTagGroupNames.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(name: selection));
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(labelText: 'Tag Group Name'),
                              onChanged: (value) {
                                tagGroup.name = value;
                              },
                              onFieldSubmitted: (value) {
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
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _musicPiece.tagGroups.remove(tagGroup);
                            _tagInputControllers[tagGroup.id]?.dispose();
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
                        value: tagGroup.color, // Use tagGroup.color directly, can be null
                        onChanged: (int? newColor) {
                          _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(color: newColor));
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
                                    color: Color(option['value'] as int),
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
                          final updatedTags = List<String>.from(tagGroup.tags).where((t) => t != tag).toList();
                          _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(tags: updatedTags));
                        },
                      );
                    }).toList(),
                  ),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _getAllTagsForTagGroup(tagGroup.name).then((allTags) {
                        return allTags.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      });
                    },
                    onSelected: (String selection) {
                      if (!tagGroup.tags.contains(selection)) {
                        final updatedTags = List<String>.from(tagGroup.tags)..add(selection);
                        _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(tags: updatedTags));
                      }
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Add new tag'),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            final tagsToAdd = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                            final updatedTags = List<String>.from(tagGroup.tags)..addAll(tagsToAdd);
                            _updateTagGroupInMusicPiece(tagGroup, tagGroup.copyWith(tags: updatedTags));
                          }
                          textEditingController.clear(); // Clear this specific controller
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
                child: Icon(Icons.drag_handle),
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
                      setState(() {
                        item.title = newTitle;
                      });
                    },
                    isEditable: true,
                  ),
                  if (item.type == MediaType.markdown)
                    TextFormField(
                      initialValue: item.pathOrUrl,
                      decoration: const InputDecoration(labelText: 'Markdown Content', border: OutlineInputBorder()),
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
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
