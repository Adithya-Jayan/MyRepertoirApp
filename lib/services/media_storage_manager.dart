import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class MediaStorageManager {
  static const String _storagePathKey = 'appStoragePath';

  static Future<String?> getStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storagePathKey);
  }

  static Future<Directory> getMediaDirectory() async {
    final storagePath = await getStoragePath();
    if (storagePath == null) {
      throw Exception('Storage path not configured');
    }
    final mediaDir = Directory(path.join(storagePath, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  static Future<String> copyMediaToLocal(String originalPath) async {
    final mediaDir = await getMediaDirectory();
    final originalFile = File(originalPath);
    if (!await originalFile.exists()) {
      throw Exception('Original file does not exist: $originalPath');
    }

    final originalName = path.basename(originalPath);
    final extension = path.extension(originalName);
    final nameWithoutExt = path.basenameWithoutExtension(originalName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${nameWithoutExt}_$timestamp$extension';

    final newPath = path.join(mediaDir.path, newFileName);

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
}
