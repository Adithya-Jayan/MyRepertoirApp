import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_type.dart';

class MediaStorageManager {
  static const String _storagePathKey = 'appStoragePath';

  static Future<String?> getStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storagePathKey);
  }

  static Future<Directory> getPieceMediaDirectory(String pieceId, MediaType mediaType) async {
    final storagePath = await getStoragePath();
    if (storagePath == null) {
      throw Exception('Storage path not configured');
    }
    final mediaTypeString = mediaType.toString().split('.').last;
    final pieceMediaDir = Directory(path.join(storagePath, 'media', pieceId, mediaTypeString));
    if (!await pieceMediaDir.exists()) {
      await pieceMediaDir.create(recursive: true);
    }
    return pieceMediaDir;
  }

  static Future<String> copyMediaToLocal(String originalPath, String pieceId, MediaType mediaType) async {
    final pieceMediaDir = await getPieceMediaDirectory(pieceId, mediaType);
    final originalFile = File(originalPath);
    if (!await originalFile.exists()) {
      throw Exception('Original file does not exist: $originalPath');
    }

    final originalName = path.basename(originalPath);
    final extension = path.extension(originalName);
    final nameWithoutExt = path.basenameWithoutExtension(originalName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${nameWithoutExt}_$timestamp$extension';

    final newPath = path.join(pieceMediaDir.path, newFileName);

    await originalFile.copy(newPath);

    return newPath;
  }

  static Future<bool> isFileInLocalStorage(String filePath) async {
    final storagePath = await getStoragePath();
    if (storagePath == null) return false;

    final mediaDir = path.join(storagePath, 'media');
    return filePath.startsWith(mediaDir);
  }

  static Future<void> deleteLocalMediaFile(String filePath) async {
    if (!await isFileInLocalStorage(filePath)) {
      return;
    }

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> deletePieceMediaDirectory(String pieceId) async {
    final storagePath = await getStoragePath();
    if (storagePath == null) return;

    final pieceDir = Directory(path.join(storagePath, 'media', pieceId));
    if (await pieceDir.exists()) {
        await pieceDir.delete(recursive: true);
    }
  }
}