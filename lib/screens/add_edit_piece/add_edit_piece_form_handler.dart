import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/music_piece.dart';
import '../../models/media_item.dart';
import '../../models/tag_group.dart';
import '../../models/group.dart';
import '../../database/music_piece_repository.dart';
import '../../services/thumbnail_service.dart';
import '../../utils/app_logger.dart';

class AddEditPieceFormHandler {
  final MusicPieceRepository repository;
  final MusicPiece? originalMusicPiece;

  AddEditPieceFormHandler({
    required this.repository,
    this.originalMusicPiece,
  });

  MusicPiece createInitialMusicPiece(String? selectedGroupId) {
    if (originalMusicPiece != null) {
      return originalMusicPiece!.copyWith(
        mediaItems: originalMusicPiece!.mediaItems.map((item) => 
          MediaItem(
            id: item.id,
            type: item.type,
            pathOrUrl: item.pathOrUrl,
            title: item.title,
            thumbnailPath: item.thumbnailPath,
          )
        ).toList(),
        tagGroups: originalMusicPiece!.tagGroups.map((tagGroup) => 
          TagGroup(
            id: tagGroup.id,
            name: tagGroup.name,
            tags: List<String>.from(tagGroup.tags),
            color: tagGroup.color,
          )
        ).toList(),
        groupIds: List<String>.from(originalMusicPiece!.groupIds),
      );
    } else {
      final groupIds = selectedGroupId != null ? [selectedGroupId] : <String>[];
      return MusicPiece(
        id: const Uuid().v4(), 
        title: '', 
        artistComposer: '', 
        mediaItems: [], 
        tagGroups: [],
        groupIds: groupIds,
      );
    }
  }

  Future<bool> validateAndSave(
    GlobalKey<FormState> formKey,
    MusicPiece musicPiece,
    Set<String> selectedGroupIds,
  ) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    try {
      formKey.currentState!.save();

      // Fetch thumbnails for all media items
      for (var item in musicPiece.mediaItems) {
        await ThumbnailService.fetchAndSaveThumbnail(item, musicPiece.id);
      }

      // Update group IDs
      final updatedMusicPiece = musicPiece.copyWith(
        groupIds: selectedGroupIds.toList(),
      );

      // Save to database
      if (originalMusicPiece == null) {
        await repository.insertMusicPiece(updatedMusicPiece);
        AppLogger.log('Music piece inserted successfully');
      } else {
        await repository.updateMusicPiece(updatedMusicPiece);
        AppLogger.log('Music piece updated successfully');
      }

      return true;
    } catch (e) {
      AppLogger.log('Error saving music piece: $e');
      return false;
    }
  }

  Future<List<Group>> loadGroups() async {
    try {
      return await repository.getGroups();
    } catch (e) {
      AppLogger.log('Error loading groups: $e');
      return [];
    }
  }
} 