import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:repertoire/models/contributor.dart';
import 'package:repertoire/utils/app_logger.dart';

/// Loads contributor data from the `assets/contributors.json` file.
///
/// This function reads the JSON file, decodes it, and maps the data
/// to a list of [Contributor] objects.
Future<List<Contributor>> loadContributors() async {
  final jsonString = await rootBundle.loadString('assets/contributors.json'); // Load the JSON string from assets.
  final List<dynamic> jsonData = jsonDecode(jsonString); // Decode the JSON string into a list of dynamic objects.
  return jsonData.map((item) => Contributor.fromJson(item)).toList(); // Convert each JSON object to a Contributor object.
}

/// Downloads and caches contributor profile pictures for faster loading
class ContributorImageCache {
  static const String _cacheDirName = 'contributor_avatars';
  static Directory? _cacheDir;

  /// Initializes the cache directory
  static Future<void> _initCacheDir() async {
    if (_cacheDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(p.join(appDir.path, _cacheDirName));
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      AppLogger.log('ContributorImageCache: Cache directory initialized at ${_cacheDir!.path}');
    }
  }

  /// Gets the cached image file path for a contributor
  static Future<String> _getCachedImagePath(String login) async {
    await _initCacheDir();
    return p.join(_cacheDir!.path, '${login}_avatar.jpg');
  }

  /// Downloads and caches a contributor's avatar
  static Future<String?> downloadAndCacheAvatar(String login, String avatarUrl) async {
    try {
      AppLogger.log('ContributorImageCache: Downloading avatar for $login from $avatarUrl');
      
      final response = await http.get(Uri.parse(avatarUrl));
      if (response.statusCode == 200) {
        final cachedPath = await _getCachedImagePath(login);
        final file = File(cachedPath);
        await file.writeAsBytes(response.bodyBytes);
        
        AppLogger.log('ContributorImageCache: Avatar cached for $login at $cachedPath');
        return cachedPath;
      } else {
        AppLogger.log('ContributorImageCache: Failed to download avatar for $login. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.log('ContributorImageCache: Error downloading avatar for $login: $e');
      return null;
    }
  }

  /// Gets the cached avatar path, downloading it if not cached
  static Future<String?> getCachedAvatarPath(String login, String avatarUrl) async {
    final cachedPath = await _getCachedImagePath(login);
    final file = File(cachedPath);
    
    if (await file.exists()) {
      AppLogger.log('ContributorImageCache: Using cached avatar for $login');
      return cachedPath;
    } else {
      AppLogger.log('ContributorImageCache: Avatar not cached for $login, downloading...');
      return await downloadAndCacheAvatar(login, avatarUrl);
    }
  }

  /// Preloads all contributor avatars in the background
  static Future<void> preloadAllAvatars(List<Contributor> contributors) async {
    AppLogger.log('ContributorImageCache: Starting preload of ${contributors.length} avatars');
    
    for (final contributor in contributors) {
      try {
        await getCachedAvatarPath(contributor.login, contributor.avatarUrl);
        // Add a small delay to avoid overwhelming the network
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        AppLogger.log('ContributorImageCache: Error preloading avatar for ${contributor.login}: $e');
      }
    }
    
    AppLogger.log('ContributorImageCache: Avatar preload completed');
  }

  /// Clears the avatar cache
  static Future<void> clearCache() async {
    try {
      await _initCacheDir();
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
        AppLogger.log('ContributorImageCache: Cache cleared');
      }
    } catch (e) {
      AppLogger.log('ContributorImageCache: Error clearing cache: $e');
    }
  }
}