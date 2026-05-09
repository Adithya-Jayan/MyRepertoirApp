import 'package:repertoire/models/tag_group.dart';
import 'package:flutter/material.dart';
import '../models/music_piece.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/learning_progress_config.dart';
import '../widgets/add_edit_piece/learning_progress_config_dialog.dart';

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

  final ScrollController _scrollController = ScrollController();
  String? _newlyAddedId;
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _initializeManagers();
    _initializeMusicPiece();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToItem(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[id];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onMediaItemsChanged(List<MediaItem> newMediaItems) {
    final currentIds = _musicPiece.mediaItems.map((e) => e.id).toSet();
    final newId = newMediaItems.map((e) => e.id).firstWhere((id) => !currentIds.contains(id), orElse: () => '');

    setState(() {
      _musicPiece = _musicPiece.copyWith(mediaItems: newMediaItems);
      if (newId.isNotEmpty) {
        _newlyAddedId = newId;
        _scrollToItem(newId);
      }
    });
  }

  void _onTagGroupsChanged(List<TagGroup> newTagGroups) {
    AppLogger.log('AddEditPieceScreen: Tag groups updated - ${newTagGroups.length} groups');
    final currentIds = _musicPiece.tagGroups.map((e) => e.id).toSet();
    final newId = newTagGroups.map((e) => e.id).firstWhere((id) => !currentIds.contains(id), orElse: () => '');

    setState(() {
      _musicPiece = _musicPiece.copyWith(tagGroups: newTagGroups);
      if (newId.isNotEmpty) {
        _newlyAddedId = newId;
        _scrollToItem(newId);
      }
    });
  }

  Future<void> _handleUpdateTagGroup(TagGroup oldGroup, TagGroup newGroup, {bool isAutofill = false}) async {
    if (!isAutofill && oldGroup.color != newGroup.color && newGroup.color != null) {
      final shouldUpdateAll = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update All?'),
          content: Text('Do you want to update the color of tag group "${newGroup.name}" across all pieces?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldUpdateAll == true) {
        final repository = MusicPieceRepository();
        await repository.updateTagGroupColor(newGroup.name, newGroup.color!);
      }
    }
    _tagManager.updateTagGroup(oldGroup, newGroup, _musicPiece.tagGroups);
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

  bool _hasChanges() {
    // Basic fields
    if (_musicPiece.title != (widget.musicPiece?.title ?? '') ||
        _musicPiece.artistComposer != (widget.musicPiece?.artistComposer ?? 'Unknown Artist') ||
        _musicPiece.enablePracticeTracking != (widget.musicPiece?.enablePracticeTracking ?? true)) {
      return true;
    }

    // Groups
    final originalGroupIds = widget.musicPiece?.groupIds.toSet() ?? (widget.selectedGroupId != null ? {widget.selectedGroupId!} : <String>{});
    if (_selectedGroupIds.length != originalGroupIds.length || !_selectedGroupIds.containsAll(originalGroupIds)) {
      return true;
    }

    // Tag groups (Deep compare)
    final originalTagGroups = widget.musicPiece?.tagGroups ?? [];
    if (_musicPiece.tagGroups.length != originalTagGroups.length) return true;
    for (int i = 0; i < _musicPiece.tagGroups.length; i++) {
      if (_musicPiece.tagGroups[i].name != originalTagGroups[i].name ||
          _musicPiece.tagGroups[i].color != originalTagGroups[i].color ||
          _musicPiece.tagGroups[i].tags.join(',') != originalTagGroups[i].tags.join(',')) {
        return true;
      }
    }

    // Media items
    final originalMediaItems = widget.musicPiece?.mediaItems ?? [];
    if (_musicPiece.mediaItems.length != originalMediaItems.length) return true;
    for (int i = 0; i < _musicPiece.mediaItems.length; i++) {
      if (_musicPiece.mediaItems[i].id != originalMediaItems[i].id ||
          _musicPiece.mediaItems[i].pathOrUrl != originalMediaItems[i].pathOrUrl) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('AddEditPieceScreen: build called');
    final hasThumbnail = _musicPiece.mediaItems.any((item) => item.type == MediaType.thumbnails);

    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          
          if (!_hasChanges()) {
            if (mounted) Navigator.of(context).pop();
            return;
          }

          final navigator = Navigator.of(context);
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );

          if (shouldPop == true && mounted) {
            navigator.pop();
          }
        },
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
                controller: _scrollController,
                children: [
                  BasicDetailsSection(
                    musicPiece: _musicPiece,
                    onTitleChanged: (value) => _musicPiece.title = value,
                    onArtistComposerChanged: (value) => _musicPiece.artistComposer = value,
                    onSaveRequested: _savePiece,
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
                    onUpdateTagGroup: _handleUpdateTagGroup,
                    onDeleteTagGroup: (tagGroup) => 
                      _tagManager.deleteTagGroup(tagGroup, _musicPiece.tagGroups),
                    onGetAllTagsForTagGroup: _tagManager.getAllTagsForTagGroup,
                    onReorderTagGroups: (oldIndex, newIndex) => 
                      _tagManager.reorderTagGroups(oldIndex, newIndex, _musicPiece.tagGroups),
                    onAddTagGroup: () => _tagManager.addTagGroup(_musicPiece.tagGroups),
                    onFetchMostCommonColor: _fetchMostCommonColor,
                    newlyAddedId: _newlyAddedId,
                    onHighlightComplete: () {
                      setState(() {
                        _newlyAddedId = null;
                      });
                    },
                    itemKeys: _itemKeys,
                  ),
                  const SizedBox(height: 20),
                  MediaSectionWidget(
                    musicPiece: _musicPiece,
                    onMusicPieceChanged: (updatedMusicPiece) {
                      setState(() {
                        _musicPiece = updatedMusicPiece;
                      });
                    },
                    newlyAddedId: _newlyAddedId,
                    onHighlightComplete: () {
                      setState(() {
                        _newlyAddedId = null;
                      });
                    },
                    itemKeys: _itemKeys,
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: SpeedDialWidget(
            hasThumbnail: hasThumbnail,
            onAddMediaItem: (mediaType) async {
              if (mediaType == MediaType.learningProgress) {
                final config = await showDialog<LearningProgressConfig>(
                  context: context,
                  builder: (context) => const LearningProgressConfigDialog(),
                );
                if (config != null) {
                  final configJson = LearningProgressConfig.encode(config);
                  _mediaManager.addMediaItem(mediaType, List<MediaItem>.from(_musicPiece.mediaItems), configData: configJson);
                }
              } else {
                _mediaManager.addMediaItem(mediaType, List<MediaItem>.from(_musicPiece.mediaItems));
              }
            },
          ),
        ),
      ),
    );
  }
}
