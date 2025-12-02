import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class UpdateService {
  static const String _githubRepo = 'Adithya-Jayan/MyRepertoirApp';
  static const String _githubApiUrl = 'https://api.github.com/repos/$_githubRepo/releases/latest';
  static const String _githubTagsUrl = 'https://api.github.com/repos/$_githubRepo/releases/tags';
  static const String _githubUrl = 'https://github.com/$_githubRepo/releases';
  static const String _fdroidUrl = 'https://f-droid.org/packages/io.github.adithya_jayan.myrepertoirapp.fdroid/';

  /// Checks for updates and shows a dialog if a new version is available.
  Future<void> checkForUpdates(BuildContext context, {bool manual = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final shouldNotify = prefs.getBool('notifyNewReleases') ?? false;

    if (!manual && !shouldNotify) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      final currentVersion = Version.parse(currentVersionStr);
      
      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> releaseData = jsonDecode(response.body);
        String tagName = releaseData['tag_name'];
        if (tagName.startsWith('v')) tagName = tagName.substring(1);
        
        // strip build info if present in tag
        if (tagName.contains('+')) tagName = tagName.split('+')[0];

        final latestVersion = Version.parse(tagName);

        // Compare ignoring build numbers (Version(major, minor, patch) does this)
        final currentBase = Version(currentVersion.major, currentVersion.minor, currentVersion.patch);
        final latestBase = Version(latestVersion.major, latestVersion.minor, latestVersion.patch);

        AppLogger.log('UpdateService: Current: $currentBase, Latest: $latestBase');

        if (latestBase > currentBase) {
          if (!manual) {
            final dismissedVersion = prefs.getString('dismissed_update_version');
            if (dismissedVersion == tagName) return;
          }

          if (context.mounted) {
            _showUpdateAvailableDialog(context, tagName);
          }
        } else if (manual && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('You are on the latest version.')),
           );
        }
      }
    } catch (e) {
      AppLogger.log('UpdateService: Error checking for updates: $e');
      if (manual && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Checks if the app was recently updated and shows the changelog.
  Future<void> showChangelogOnStartup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRunVersionStr = prefs.getString('last_run_version');
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionStr = packageInfo.version;

    if (lastRunVersionStr == null) {
      // First run, just save current version and return
      await prefs.setString('last_run_version', currentVersionStr);
      return;
    }

    try {
      final lastRunVersion = Version.parse(lastRunVersionStr);
      final currentVersion = Version.parse(currentVersionStr);
      
      final lastRunBase = Version(lastRunVersion.major, lastRunVersion.minor, lastRunVersion.patch);
      final currentBase = Version(currentVersion.major, currentVersion.minor, currentVersion.patch);

      if (currentBase > lastRunBase) {
        // App updated
        final body = await _fetchChangelog(currentVersionStr);
        if (context.mounted) {
          if (body != null) {
            _showWhatIsNewDialog(context, currentVersionStr, body);
          } else {
            // Fallback if we can't fetch the specific changelog
            _showGenericUpdateDialog(context, currentVersionStr);
          }
        }
      }
      
      // Update stored version after checking/showing dialog
      await prefs.setString('last_run_version', currentVersionStr);

    } catch (e) {
      AppLogger.log('UpdateService: Error parsing version for changelog: $e');
      // Even on error, update the version so we don't crash repeatedly or get stuck
      await prefs.setString('last_run_version', currentVersionStr);
    }
  }

  Future<String?> _fetchChangelog(String version) async {
    try {
      // Try fetching specific tag
      // Strip build number from version if present for tag search
      String cleanVersion = version;
      if (cleanVersion.contains('+')) cleanVersion = cleanVersion.split('+')[0];

      final url = '$_githubTagsUrl/v$cleanVersion'; 
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         return data['body'];
      }
      
      final url2 = '$_githubTagsUrl/$cleanVersion';
      final response2 = await http.get(Uri.parse(url2));
      if (response2.statusCode == 200) {
         final data = jsonDecode(response2.body);
         return data['body'];
      }
    } catch (_) {}
    return null;
  }

  void _showUpdateAvailableDialog(BuildContext context, String latestVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Update Available!'),
        content: Text('Version $latestVersion is available.'),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('dismissed_update_version', latestVersion);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
          TextButton(onPressed: () => _launchUrl(_fdroidUrl), child: const Text('F-Droid')),
          FilledButton(onPressed: () => _launchUrl(_githubUrl), child: const Text('GitHub')),
        ],
      ),
    );
  }

  void _showGenericUpdateDialog(BuildContext context, String version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Updated to v$version'),
        content: const Text('The app has been updated! Check the release notes on GitHub for details.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: () => _launchUrl(_githubUrl), child: const Text('Release Notes')),
        ],
      ),
    );
  }

  void _showWhatIsNewDialog(BuildContext context, String version, String body) {
    // Fix newlines for Markdown
    final formattedBody = body.replaceAll(RegExp(r'\r\n|\r|\n'), '\n\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('What\'s New in v$version'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: MarkdownBody(data: formattedBody),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}