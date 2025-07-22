import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/media_type.dart';

/// Manages the storage of media files associated with music pieces.
///
/// This class provides methods for getting application directories, creating
/// media-specific directories for each music piece, copying media files to
/// local storage, and deleting media files and their directories.
class MediaStorageManager {
  /// Returns the application's documents directory.
  static Future<Directory> get _appDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// Returns the specific directory for a music piece's media items of a given type.
  ///
  /// Creates the directory if it doesn't already exist.
  ///
  /// If [mediaType] is MediaType.thumbnails, this returns the hierarchical thumbnail directory for the piece.
  static Future<Directory> getPieceMediaDirectory(String pieceId, MediaType mediaType) async {
    final appDir = await _appDirectory;
    final mediaTypeString = mediaType.toString().split('.').last; // Extract media type string (e.g., 'image', 'pdf').
    final pieceMediaDir = Directory(path.join(appDir.path, 'media', pieceId, mediaTypeString)); // Construct the full path.
    if (!await pieceMediaDir.exists()) {
      await pieceMediaDir.create(recursive: true); // Create the directory recursively if it doesn't exist.
    }
    return pieceMediaDir;
  }

  /// Copies a media file from its original path to the application's local storage.
  ///
  /// The file is copied into a specific directory structured by piece ID and media type.
  /// A unique filename is generated to prevent conflicts.
  static Future<String> copyMediaToLocal(String originalPath, String pieceId, MediaType mediaType) async {
    final pieceMediaDir = await getPieceMediaDirectory(pieceId, mediaType); // Get the target directory for the media file.
    final originalFile = File(originalPath);
    if (!await originalFile.exists()) {
      throw Exception('Original file does not exist: $originalPath'); // Throw an error if the original file is not found.
    }

    final originalName = path.basename(originalPath); // Get the base name of the original file.
    final extension = path.extension(originalName); // Get the file extension.
    final nameWithoutExt = path.basenameWithoutExtension(originalName); // Get the file name without extension.
    final timestamp = DateTime.now().millisecondsSinceEpoch; // Generate a timestamp for uniqueness.
    final newFileName = '${nameWithoutExt}_$timestamp$extension'; // Construct a new unique file name.

    final newPath = path.join(pieceMediaDir.path, newFileName); // Construct the full new path for the copied file.

    final newFile = await originalFile.copy(newPath); // Copy the file to the new path.
    return newFile.path; // Return the path of the newly copied file.
  }

  /// Checks if a given file path is within the application's local storage directory.
  static Future<bool> isFileInLocalStorage(String filePath) async {
    final appDir = await _appDirectory;
    final mediaDir = path.join(appDir.path, 'media'); // Construct the base media directory path.
    return filePath.startsWith(mediaDir); // Check if the file path starts with the media directory path.
  }

  /// Deletes a local media file if it exists within the application's storage.
  static Future<void> deleteLocalMediaFile(String filePath) async {
    if (!await isFileInLocalStorage(filePath)) {
      return; // Do nothing if the file is not in local storage.
    }

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete(); // Delete the file if it exists.
    }
  }

  /// Deletes the entire media directory associated with a specific music piece.
  ///
  /// This removes all media files (images, PDFs, audio, etc.) for that piece.
  static Future<void> deletePieceMediaDirectory(String pieceId) async {
    final appDir = await _appDirectory;
    final pieceDir = Directory(path.join(appDir.path, 'media', pieceId)); // Construct the music piece's media directory path.
    if (await pieceDir.exists()) {
        await pieceDir.delete(recursive: true); // Delete the directory and its contents recursively.
    }
  }
}
