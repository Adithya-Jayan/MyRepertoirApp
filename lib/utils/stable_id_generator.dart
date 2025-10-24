import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for generating stable, predictable IDs for music pieces
/// based on their content rather than random UUIDs
class StableIdGenerator {
  /// Generates a stable ID based on the piece's title and artist/composer
  /// This ensures that the same piece will always have the same ID
  static String generatePieceId(String title, String artistComposer) {
    // Create a unique string from title and artist
    final uniqueString = '${title.trim().toLowerCase()}_${artistComposer.trim().toLowerCase()}';
    
    // Generate SHA-256 hash
    final bytes = utf8.encode(uniqueString);
    final digest = sha256.convert(bytes);
    
    // Take first 16 characters of the hash for a shorter ID
    return digest.toString().substring(0, 16);
  }

  /// Generates a stable ID for a media item based on its content
  static String generateMediaItemId(String pieceId, String mediaType, String fileName) {
    // Create a unique string from piece ID, media type, and filename
    final uniqueString = '${pieceId}_${mediaType}_${fileName.trim().toLowerCase()}';
    
    // Generate SHA-256 hash
    final bytes = utf8.encode(uniqueString);
    final digest = sha256.convert(bytes);
    
    // Take first 12 characters of the hash for a shorter ID
    return digest.toString().substring(0, 12);
  }

  /// Generates a stable thumbnail ID for a piece
  static String generateThumbnailId(String pieceId) {
    // Create a unique string for thumbnail
    final uniqueString = '${pieceId}_thumbnail';
    
    // Generate SHA-256 hash
    final bytes = utf8.encode(uniqueString);
    final digest = sha256.convert(bytes);
    
    // Take first 12 characters of the hash for a shorter ID
    return digest.toString().substring(0, 12);
  }

  /// Validates if an ID looks like a stable ID (16 hex characters)
  static bool isStableId(String id) {
    return id.length == 16 && RegExp(r'^[a-f0-9]+$').hasMatch(id);
  }

  /// Validates if an ID looks like a media ID (12 hex characters)
  static bool isMediaId(String id) {
    return id.length == 12 && RegExp(r'^[a-f0-9]+$').hasMatch(id);
  }
} 