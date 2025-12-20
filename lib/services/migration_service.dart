import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/music_piece_repository.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../utils/app_logger.dart';

class MigrationService {
  final MusicPieceRepository _repository;
  final SharedPreferences _prefs;

  MigrationService(this._repository, this._prefs);

  static const String _migrationKeyThumbnailWidgets = 'migration_thumbnail_widgets_created';

  /// Runs all pending data migrations.
  Future<void> runMigrations() async {
    AppLogger.log('MigrationService: Checking for pending migrations...');
    
    await _migrateThumbnailWidgets();
    
    AppLogger.log('MigrationService: All checks completed.');
  }

  /// Ensures that any MusicPiece with a thumbnailPath has a corresponding MediaType.thumbnails widget.
  Future<void> _migrateThumbnailWidgets() async {
    // Check if this migration has already run
    final hasRun = _prefs.getBool(_migrationKeyThumbnailWidgets) ?? false;
    if (hasRun) {
      AppLogger.log('MigrationService: Thumbnail widgets migration already applied. Skipping.');
      return;
    }

    AppLogger.log('MigrationService: Running thumbnail widgets migration...');
    try {
      final allPieces = await _repository.getMusicPieces();
      int updatedCount = 0;

      for (final piece in allPieces) {
        if (piece.thumbnailPath != null && piece.thumbnailPath!.isNotEmpty) {
          final thumbnailPath = piece.thumbnailPath!;
          
          // Check if a corresponding MediaType.thumbnails widget exists
          final hasThumbnailWidget = piece.mediaItems.any((item) => 
            item.type == MediaType.thumbnails && item.pathOrUrl == thumbnailPath
          );

          if (!hasThumbnailWidget) {
            AppLogger.log('MigrationService: Creating missing thumbnail widget for piece: ${piece.title}');
            
            final newThumbnailItem = MediaItem(
              id: const Uuid().v4(),
              type: MediaType.thumbnails,
              pathOrUrl: thumbnailPath,
            );

            // Create updated list of media items
            final updatedMediaItems = List<MediaItem>.from(piece.mediaItems);
            updatedMediaItems.add(newThumbnailItem);

            // Update the piece
            final updatedPiece = piece.copyWith(mediaItems: updatedMediaItems);
            await _repository.updateMusicPiece(updatedPiece);
            updatedCount++;
          }
        }
      }

      // Mark migration as done
      await _prefs.setBool(_migrationKeyThumbnailWidgets, true);
      AppLogger.log('MigrationService: Thumbnail widgets migration completed. Updated $updatedCount pieces.');
      
    } catch (e) {
      AppLogger.log('MigrationService: Error running thumbnail widgets migration: $e');
      // Do not mark as done so it retries next time
    }
  }
}
