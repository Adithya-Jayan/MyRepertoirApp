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
import '../widgets/add_edit_piece/groups_section.dart';
import '../widgets/add_edit_piece/tag_groups_section.dart';
import '../widgets/add_edit_piece/media_section.dart';
import '../widgets/add_edit_piece/speed_dial_widget.dart';
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

  Future<int?> _fetchMostCommonColor(String tagName) async {
    return await _tagManager.getMostCommonColorForTagGroup(tagName);
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
    return SafeArea(
      child: Scaffold(
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
              GroupsSection(
                availableGroups: _availableGroups,
                selectedGroupIds: _selectedGroupIds,
                onGroupIdsChanged: (newGroupIds) {
                  setState(() {
                    _selectedGroupIds = newGroupIds;
                  });
                },
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Enable Practice Tracking'),
                value: _musicPiece.enablePracticeTracking,
                onChanged: (bool value) {
                  setState(() {
                    _musicPiece = _musicPiece.copyWith(enablePracticeTracking: value);
                  });
                },
              ),
              const SizedBox(height: 20),
              TagGroupsSection(
                tagGroups: _musicPiece.tagGroups,
                allTagGroupNames: _allTagGroupNames,
                onUpdateTagGroup: (oldGroup, newGroup) => 
                  _tagManager.updateTagGroup(oldGroup, newGroup, _musicPiece.tagGroups),
                onDeleteTagGroup: (tagGroup) => 
                  _tagManager.deleteTagGroup(tagGroup, _musicPiece.tagGroups),
                onGetAllTagsForTagGroup: _tagManager.getAllTagsForTagGroup,
                onReorderTagGroups: (oldIndex, newIndex) => 
                  _tagManager.reorderTagGroups(oldIndex, newIndex, _musicPiece.tagGroups),
                onAddTagGroup: () => _tagManager.addTagGroup(_musicPiece.tagGroups),
                onFetchMostCommonColor: _fetchMostCommonColor,
              ),
              const SizedBox(height: 20),
              MediaSectionWidget(
                mediaItems: _musicPiece.mediaItems,
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
                onReorderMediaItems: (oldIndex, newIndex) {
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
          ),
        ),
      ),
      floatingActionButton: SpeedDialWidget(
        onAddMediaItem: (mediaType) => _mediaManager.addMediaItem(mediaType, List<MediaItem>.from(_musicPiece.mediaItems)),
      ),
    );
  }


}