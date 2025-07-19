import 'package:repertoire/models/tag_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/group.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';
import '../widgets/add_edit_piece/basic_details_section.dart';
import '../widgets/detail_widgets/tag_group_section.dart';
import '../widgets/detail_widgets/media_section.dart';
import '../widgets/detail_widgets/media_display_list.dart';
import 'add_edit_piece/add_edit_piece_media_manager.dart';
import 'add_edit_piece/add_edit_piece_tag_manager.dart';
import 'add_edit_piece/add_edit_piece_form_handler.dart';

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
  List<String> _allTagGroupNames = [];
  
  late final AddEditPieceMediaManager _mediaManager;
  late final AddEditPieceTagManager _tagManager;
  late final AddEditPieceFormHandler _formHandler;

  @override
  void initState() {
    super.initState();
    _initializeManagers();
    _initializeMusicPiece();
    _loadData();
  }

  void _initializeManagers() {
    final repository = MusicPieceRepository();
    _mediaManager = AddEditPieceMediaManager(
      musicPieceId: widget.musicPiece?.id ?? '',
      onMediaItemsChanged: _onMediaItemsChanged,
    );
    _tagManager = AddEditPieceTagManager(
      repository: repository,
      onTagGroupsChanged: _onTagGroupsChanged,
    );
    _formHandler = AddEditPieceFormHandler(
      repository: repository,
      originalMusicPiece: widget.musicPiece,
    );
  }

  void _initializeMusicPiece() {
    _musicPiece = _formHandler.createInitialMusicPiece(widget.selectedGroupId);
    _selectedGroupIds = Set<String>.from(_musicPiece.groupIds);
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadGroups(),
      _loadTagGroupNames(),
    ]);
  }

  Future<void> _loadGroups() async {
    final groups = await _formHandler.loadGroups();
    setState(() {
      _availableGroups = groups;
    });
  }

  Future<void> _loadTagGroupNames() async {
    final tagGroupNames = await _tagManager.loadTagGroupNames();
    setState(() {
      _allTagGroupNames = tagGroupNames;
    });
  }

  void _onMediaItemsChanged(List<MediaItem> newMediaItems) {
    setState(() {
      _musicPiece = _musicPiece.copyWith(mediaItems: newMediaItems);
    });
  }

  void _onTagGroupsChanged(List<TagGroup> newTagGroups) {
    AppLogger.log('AddEditPieceScreen: Tag groups updated - ${newTagGroups.length} groups');
    setState(() {
      _musicPiece = _musicPiece.copyWith(tagGroups: newTagGroups);
    });
  }

  void _setThumbnail(String path) {
    setState(() {
      _musicPiece = _musicPiece.copyWith(thumbnailPath: path);
    });
  }

  bool _isSaving = false;

  Future<void> _savePiece() async {
    if (_isSaving) return; // Prevent multiple saves
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final success = await _formHandler.validateAndSave(
        _formKey,
        _musicPiece,
        _selectedGroupIds,
      );
      
      if (success && mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePiece,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              BasicDetailsSection(
                musicPiece: _musicPiece,
                onTitleChanged: (value) => _musicPiece.title = value,
                onArtistComposerChanged: (value) => _musicPiece.artistComposer = value,
              ),
              const SizedBox(height: 20),
              _buildGroupsSection(),
              const SizedBox(height: 20),
              _buildTagGroupsSection(),
              const SizedBox(height: 20),
              _buildMediaSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildGroupsSection() {
    return ExpansionTile(
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
    );
  }

  Widget _buildTagGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tag Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _tagManager.addTagGroup(_musicPiece.tagGroups),
              tooltip: 'Add Tag Group',
            ),
          ],
        ),
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
              onUpdateTagGroup: (oldGroup, newGroup) => 
                _tagManager.updateTagGroup(oldGroup, newGroup, _musicPiece.tagGroups),
              onDeleteTagGroup: (tagGroup) => 
                _tagManager.deleteTagGroup(tagGroup, _musicPiece.tagGroups),
              onGetAllTagsForTagGroup: _tagManager.getAllTagsForTagGroup,
            );
          },
          onReorder: (oldIndex, newIndex) => 
            _tagManager.reorderTagGroups(oldIndex, newIndex, _musicPiece.tagGroups),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
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
              musicPieceId: _musicPiece.id,
              onUpdateMediaItem: (updatedItem) {
                setState(() {
                  final updatedMediaItems = List<MediaItem>.from(_musicPiece.mediaItems);
                  final itemIndex = updatedMediaItems.indexWhere((element) => element.id == updatedItem.id);
                  if (itemIndex != -1) {
                    updatedMediaItems[itemIndex] = updatedItem;
                    _musicPiece = _musicPiece.copyWith(mediaItems: updatedMediaItems);
                  }
                });
              },
              onDeleteMediaItem: (itemToDelete) {
                setState(() {
                  final updatedMediaItems = List<MediaItem>.from(_musicPiece.mediaItems);
                  updatedMediaItems.removeWhere((element) => element.id == itemToDelete.id);
                  _musicPiece = _musicPiece.copyWith(mediaItems: updatedMediaItems);
                });
              },
              onSetThumbnail: (path) {
                setState(() {
                  _musicPiece = _musicPiece.copyWith(thumbnailPath: path);
                });
              },
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = _musicPiece.mediaItems.removeAt(oldIndex);
              _musicPiece.mediaItems.insert(newIndex, item);
              _musicPiece = _musicPiece.copyWith(mediaItems: _musicPiece.mediaItems);
            });
          },
        ),
      ],
    );
  }



  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.text_fields),
          label: 'Markdown Text',
          onTap: () => _mediaManager.addMediaItem(MediaType.markdown, _musicPiece.mediaItems),
        ),
        SpeedDialChild(
          child: const Icon(Icons.picture_as_pdf),
          label: 'PDF',
          onTap: () => _mediaManager.addMediaItem(MediaType.pdf, _musicPiece.mediaItems),
        ),
        SpeedDialChild(
          child: const Icon(Icons.image),
          label: 'Image',
          onTap: () => _mediaManager.addMediaItem(MediaType.image, _musicPiece.mediaItems),
        ),
        SpeedDialChild(
          child: const Icon(Icons.audiotrack),
          label: 'Audio',
          onTap: () => _mediaManager.addMediaItem(MediaType.audio, _musicPiece.mediaItems),
        ),
        SpeedDialChild(
          child: const Icon(Icons.video_library),
          label: 'Link',
          onTap: () => _mediaManager.addMediaItem(MediaType.mediaLink, _musicPiece.mediaItems),
        ),
      ],
    );
  }
}