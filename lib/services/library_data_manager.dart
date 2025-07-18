import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/group.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/utils/app_logger.dart';
import 'package:repertoire/utils/music_piece_filter.dart';

class LibraryDataManager {
  final MusicPieceRepository _repository;
  final SharedPreferences _prefs;
  final ValueNotifier<bool> _isLoadingNotifier;
  final ValueNotifier<String?> _errorMessageNotifier;
  final ValueNotifier<List<MusicPiece>> _allMusicPiecesNotifier;
  final ValueNotifier<List<MusicPiece>> _musicPiecesNotifier;
  final ValueNotifier<List<Group>> _groupsNotifier;
  final ValueNotifier<int> _galleryColumnsNotifier;

  LibraryDataManager(
    this._repository,
    this._prefs,
    this._isLoadingNotifier,
    this._errorMessageNotifier,
    this._allMusicPiecesNotifier,
    this._musicPiecesNotifier,
    this._groupsNotifier,
    this._galleryColumnsNotifier,
  );

  Future<void> loadInitialData() async {
    await loadGroups();
    await loadMusicPieces();
    await loadSettings();
  }

  Future<void> loadSettings() async {
    AppLogger.log('LibraryDataManager: _loadSettings called');
    int defaultColumns;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      defaultColumns = 4;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      defaultColumns = 6;
    } else {
      defaultColumns = 2;
    }
    final loadedColumns = _prefs.getInt('galleryColumns') ?? defaultColumns;
    AppLogger.log('Loaded galleryColumns: $loadedColumns');
    _galleryColumnsNotifier.value = loadedColumns;
  }

  Future<void> loadGroups() async {
    AppLogger.log('LibraryDataManager: _loadGroups called');
    _isLoadingNotifier.value = true;
    _errorMessageNotifier.value = null;
    try {
      final allDbGroups = await _repository.getGroups();
      AppLogger.log('LibraryDataManager: Loaded ${allDbGroups.length} groups from DB.');

      final allGroupOrder = _prefs.getInt('all_group_order') ?? -2;
      final allGroupIsHidden = _prefs.getBool('all_group_isHidden') ?? true;
      final ungroupedGroupOrder = _prefs.getInt('ungrouped_group_order') ?? -1;
      final ungroupedGroupIsHidden = _prefs.getBool('ungrouped_group_isHidden') ?? false;

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

      List<Group> combinedGroups = [allGroup, ungroupedGroup, ...allDbGroups];

      combinedGroups.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });

      _groupsNotifier.value = combinedGroups;
      AppLogger.log('LibraryDataManager: All groups (including special): ${_groupsNotifier.value.map((g) => '${g.name} (id: ${g.id}, order: ${g.order}, hidden: ${g.isHidden})').join(', ')}');
    } catch (e) {
      _errorMessageNotifier.value = 'Failed to load groups: $e';
      AppLogger.log('LibraryDataManager: Error loading groups: $e');
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  Future<void> loadMusicPieces({
    String? selectedGroupId,
    String? searchQuery,
    Map<String, dynamic>? filterOptions,
    String? sortOption,
  }) async {
    _isLoadingNotifier.value = true;
    _errorMessageNotifier.value = null;
    try {
      _allMusicPiecesNotifier.value = await _repository.getMusicPieces();

      List<MusicPiece> currentPieces = _allMusicPiecesNotifier.value;

      if (selectedGroupId != null && selectedGroupId != 'all_group') {
        if (selectedGroupId == 'ungrouped_group') {
          currentPieces = currentPieces.where((piece) => piece.groupIds.isEmpty).toList();
        } else {
          currentPieces = currentPieces.where((piece) => piece.groupIds.contains(selectedGroupId)).toList();
        }
      }

      final filter = MusicPieceFilter(
        searchQuery: searchQuery ?? '',
        filterOptions: filterOptions ?? {},
        sortOption: sortOption ?? 'alphabetical_asc',
      );
      _musicPiecesNotifier.value = filter.filterAndSort(currentPieces);
    } catch (e) {
      _errorMessageNotifier.value = 'Failed to load music pieces: $e';
      AppLogger.log('LibraryDataManager: Error loading music pieces: $e');
    } finally {
      _isLoadingNotifier.value = false;
    }
  }
}
