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

class AddEditPieceScreen extends StatefulWidget {
  final MusicPiece? musicPiece;

  const AddEditPieceScreen({super.key, this.musicPiece});

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
    _loadGroups();
    _loadTagGroupNames();
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
    } else if (type == MediaType.videoLink) {
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
    if (type == MediaType.videoLink || type == MediaType.markdown) {
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
      _musicPiece.tagGroups.add(TagGroup(id: const Uuid().v4(), name: '', tags: []));
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
              const Text('Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 20),
              const Text('Tag Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._musicPiece.tagGroups.map((tagGroup) => _buildTagGroupSection(tagGroup)).toList(),
              const SizedBox(height: 20),
              const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._musicPiece.mediaItems.map((item) => _buildMediaSection(item)).toList(),
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
            label: 'Video Link',
            onTap: () => _addMediaItem(MediaType.videoLink),
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

  Widget _buildTagGroupSection(TagGroup tagGroup) {
    final TextEditingController tagGroupNameController = TextEditingController(text: tagGroup.name);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
                        controller: tagGroupNameController,
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
                    _tagInputControllers[tagGroup.id]!.clear();
                    if (onFieldSubmitted != null) {
                      onFieldSubmitted();
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(MediaItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _musicPiece.mediaItems.remove(item);
                    });
                  },
                ),
              ],
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
    );
  }
}