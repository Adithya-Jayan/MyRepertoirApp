import '../models/practice_log.dart';
import '../utils/app_logger.dart';
import './database_helper.dart';
import './music_piece_repository.dart';
import 'package:uuid/uuid.dart';

/// A repository class that handles practice log operations.
/// This is extracted from MusicPieceRepository to reduce file size and improve organization.
class PracticeLogRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final MusicPieceRepository musicPieceRepository;
  final Uuid uuid = Uuid();

  PracticeLogRepository(this.musicPieceRepository);

  /// Inserts a new [PracticeLog] into the database.
  Future<void> insertPracticeLog(PracticeLog log) async {
    await dbHelper.insertPracticeLog(log);
  }

  /// Retrieves all [PracticeLog] objects for a specific music piece.
  Future<List<PracticeLog>> getPracticeLogsForPiece(String musicPieceId) async {
    return await dbHelper.getPracticeLogsForPiece(musicPieceId);
  }

  /// Retrieves all [PracticeLog] objects from the database.
  Future<List<PracticeLog>> getAllPracticeLogs() async {
    return await dbHelper.getAllPracticeLogs();
  }

  /// Deletes a [PracticeLog] from the database by its ID.
  /// Also updates the music piece's practice tracking data.
  Future<void> deletePracticeLog(String id) async {
    AppLogger.log('deletePracticeLog: Starting deletion of practice log $id');
    
    // Get the practice log to find the music piece ID
    final allLogs = await getAllPracticeLogs();
    final logToDelete = allLogs.firstWhere((log) => log.id == id);
    final musicPieceId = logToDelete.musicPieceId;
    AppLogger.log('deletePracticeLog: Found log for music piece $musicPieceId');
    
    // Delete the practice log
    await dbHelper.deletePracticeLog(id);
    AppLogger.log('deletePracticeLog: Practice log deleted from database');
    
    // Recalculate and update the music piece's practice tracking
    AppLogger.log('deletePracticeLog: Calling _updateMusicPiecePracticeTracking for piece $musicPieceId');
    await _updateMusicPiecePracticeTracking(musicPieceId);
    AppLogger.log('deletePracticeLog: Practice tracking updated');
  }

  /// Deletes all [PracticeLog] objects for a specific music piece.
  /// Also updates the music piece's practice tracking data.
  Future<void> deletePracticeLogsForPiece(String musicPieceId) async {
    await dbHelper.deletePracticeLogsForPiece(musicPieceId);
    
    // Recalculate and update the music piece's practice tracking
    await _updateMusicPiecePracticeTracking(musicPieceId);
  }

  /// Deletes all [PracticeLog] objects from the database.
  /// Also updates all music pieces' practice tracking data.
  Future<void> deleteAllPracticeLogs() async {
    await dbHelper.deleteAllPracticeLogs();
    
    // Update all music pieces to reset their practice tracking
    final allPieces = await musicPieceRepository.getMusicPieces();
    for (final piece in allPieces) {
      final updatedPiece = piece.copyWithExplicit(
        lastPracticeTime: null,
        practiceCount: 0,
      );
      await musicPieceRepository.updateMusicPiece(updatedPiece);
    }
  }

  /// Updates a practice log and recalculates the music piece's practice tracking.
  Future<void> updatePracticeLog(PracticeLog log) async {
    await dbHelper.updatePracticeLog(log);
    
    // Recalculate and update the music piece's practice tracking
    await _updateMusicPiecePracticeTracking(log.musicPieceId);
  }

  /// Helper method to recalculate and update a music piece's practice tracking
  /// based on its remaining practice logs.
  Future<void> _updateMusicPiecePracticeTracking(String musicPieceId) async {
    AppLogger.log('_updateMusicPiecePracticeTracking: Starting for piece $musicPieceId');
    
    // Get the current practice logs for this piece
    final practiceLogs = await getPracticeLogsForPiece(musicPieceId);
    AppLogger.log('_updateMusicPiecePracticeTracking: Found ${practiceLogs.length} practice logs');
    
    // Get the music piece
    final piece = (await musicPieceRepository.getMusicPiecesByIds([musicPieceId])).first;
    AppLogger.log('_updateMusicPiecePracticeTracking: Current piece - lastPracticeTime: ${piece.lastPracticeTime}, practiceCount: ${piece.practiceCount}');
    
    if (practiceLogs.isEmpty) {
      // No practice logs left, reset practice tracking
      AppLogger.log('_updateMusicPiecePracticeTracking: No practice logs found, setting to never practiced');
      final updatedPiece = piece.copyWithExplicit(
        lastPracticeTime: null,
        practiceCount: 0,
      );
      AppLogger.log('_updateMusicPiecePracticeTracking: Updated piece - lastPracticeTime: ${updatedPiece.lastPracticeTime}, practiceCount: ${updatedPiece.practiceCount}');
      await musicPieceRepository.updateMusicPiece(updatedPiece);
      AppLogger.log('_updateMusicPiecePracticeTracking: Piece updated in database');
    } else {
      // Calculate new practice count and last practice time
      final practiceCount = practiceLogs.length;
      final lastPracticeTime = practiceLogs
          .map((log) => log.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      
      AppLogger.log('_updateMusicPiecePracticeTracking: $practiceCount practice logs found, last practice time: $lastPracticeTime');
      final updatedPiece = piece.copyWith(
        lastPracticeTime: lastPracticeTime,
        practiceCount: practiceCount,
      );
      await musicPieceRepository.updateMusicPiece(updatedPiece);
      AppLogger.log('_updateMusicPiecePracticeTracking: Piece updated with new practice data');
    }
  }

  /// Logs a practice session for a music piece.
  /// Creates a new practice log entry and updates the music piece's practice tracking.
  Future<void> logPracticeSession(String musicPieceId, {String? notes, int durationMinutes = 0, DateTime? timestamp}) async {
    final log = PracticeLog(
      id: uuid.v4(),
      musicPieceId: musicPieceId,
      timestamp: timestamp ?? DateTime.now(),
      notes: notes,
      durationMinutes: durationMinutes,
    );
    
    await insertPracticeLog(log);
    
    // Recalculate and update the music piece's practice tracking
    await _updateMusicPiecePracticeTracking(musicPieceId);
  }
} 