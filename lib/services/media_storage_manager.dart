import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/media_type.dart';

class MediaStorageManager {
  static Future<Directory> get _appDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory> getPieceMediaDirectory(String pieceId, MediaType mediaType) async {
    final appDir = await _appDirectory;
    final mediaTypeString = mediaType.toString().split('.').last;
    final pieceMediaDir = Directory(path.join(appDir.path, 'media', pieceId, mediaTypeString));
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

    final newFile = await originalFile.copy(newPath);
    return newFile.path;
  }

  static Future<bool> isFileInLocalStorage(String filePath) async {
    final appDir = await _appDirectory;
    final mediaDir = path.join(appDir.path, 'media');
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
    final appDir = await _appDirectory;
    final pieceDir = Directory(path.join(appDir.path, 'media', pieceId));
    if (await pieceDir.exists()) {
        await pieceDir.delete(recursive: true);
    }
  }
}
