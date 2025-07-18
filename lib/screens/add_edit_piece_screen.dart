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

import '../services/media_storage_manager.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../widgets/detail_widgets/tag_group_section.dart';
import '../widgets/detail_widgets/media_section.dart';

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

  @override
  void initState() {
    super.initState();
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

    _selectedGroupIds = Set<String>.from(_musicPiece.groupIds);
    if (widget.musicPiece == null && widget.selectedGroupId != null) {
      _selectedGroupIds.add(widget.selectedGroupId!);
    }
    
    _loadGroups();
    _loadTagGroupNames();

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
    final allUniqueTags = await _repository.getAllUniqueTagGroups();
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
        _availableGroups = groups;
      });
    } catch (e) {
      AppLogger.log('Error loading groups: $e');
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
        if (!mounted) return;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying file: $e'))
        );
      }
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

  void _deleteTagGroup(TagGroup tagGroup) {
    setState(() {
      _musicPiece.tagGroups.remove(tagGroup);
      _tagInputControllers[tagGroup.id]?.dispose();
      _tagInputControllers.remove(tagGroup.id);
    });
  }

  void _updateMediaItem(MediaItem newItem) {
    final List<MediaItem> updatedMediaItems = List.from(_musicPiece.mediaItems);
    final int index = updatedMediaItems.indexWhere((element) => element.id == newItem.id);
    if (index != -1) {
      updatedMediaItems[index] = newItem;
      setState(() {
        _musicPiece = _musicPiece.copyWith(mediaItems: updatedMediaItems);
      });
    }
  }

  void _deleteMediaItem(MediaItem item) async {
    await MediaStorageManager.deleteLocalMediaFile(item.pathOrUrl);
    setState(() {
      _musicPiece.mediaItems.remove(item);
    });
  }

  void _setThumbnail(String path) {
    setState(() {
      _musicPiece = _musicPiece.copyWith(thumbnailPath: path);
    });
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
        AppLogger.log('Error fetching or saving thumbnail: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('AddEditPieceScreen: build called');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.musicPiece == null ? 'Add Piece' : 'Edit Piece'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                for (var item in _musicPiece.mediaItems) {
                  await _fetchAndSaveThumbnail(item);
                }

                _musicPiece.groupIds = _selectedGroupIds.toList();

                if (widget.musicPiece == null) {
                  await _repository.insertMusicPiece(_musicPiece);
                } else {
                  await _repository.updateMusicPiece(_musicPiece);
                }

                if (!mounted) return;
                Navigator.of(context).pop(true);
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
                  }),
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
                  return TagGroupSection(
                    key: ValueKey(tagGroup.id),
                    tagGroup: tagGroup,
                    index: index,
                    allTagGroupNames: _allTagGroupNames,
                    onUpdateTagGroup: _updateTagGroupInMusicPiece,
                    onDeleteTagGroup: _deleteTagGroup,
                    onGetAllTagsForTagGroup: _getAllTagsForTagGroup,
                  );
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
                  return MediaSection(
                    key: ValueKey(item.id),
                    item: item,
                    index: index,
                    musicPieceThumbnail: _musicPiece.thumbnailPath ?? '',
                    onUpdateMediaItem: _updateMediaItem,
                    onDeleteMediaItem: _deleteMediaItem,
                    onSetThumbnail: _setThumbnail,
                  );
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
}