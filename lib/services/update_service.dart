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
  // TODO: Replace with your actual repository
  static const String _githubRepo = 'Adithya-Mohan/MyRepertoirApp';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';
  static const String _githubUrl = 'https://github.com/$_githubRepo/releases';
  static const String _fdroidUrl = 'https://f-droid.org/packages/com.example.repertoire/'; // Replace with actual F-Droid package ID

  /// Checks for updates and shows a dialog if a new version is available.
  /// 
  /// [manual] - If true, shows a dialog even if no update is found (or if disabled).
  /// If false, respects the 'notifyNewReleases' setting.
  Future<void> checkForUpdates(BuildContext context, {bool manual = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final shouldNotify = prefs.getBool('notifyNewReleases') ?? false;

    if (!manual && !shouldNotify) {
      AppLogger.log('UpdateService: Auto-check skipped (notifyNewReleases is off).');
      return;
    }

    AppLogger.log('UpdateService: Checking for updates...');

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      final currentVersion = Version.parse(currentVersionStr);

      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> releaseData = jsonDecode(response.body);
        String tagName = releaseData['tag_name'];
        
        // Handle 'v' prefix in tags (e.g., v1.0.0)
        if (tagName.startsWith('v')) {
          tagName = tagName.substring(1);
        }

        final latestVersion = Version.parse(tagName);

        AppLogger.log('UpdateService: Current: $currentVersion, Latest: $latestVersion');

        if (latestVersion > currentVersion) {
          if (context.mounted) {
            _showUpdateDialog(context, releaseData, currentVersionStr);
          }
        } else if (manual) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('You are on the latest version.')),
             );
           }
        }
      } else {
        AppLogger.log('UpdateService: Failed to fetch release info. Status: ${response.statusCode}');
        if (manual && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to check for updates.')),
           );
        }
      }
    } catch (e) {
      AppLogger.log('UpdateService: Error checking for updates: $e');
      if (manual && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
         );
      }
    }
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> releaseData, String currentVersion) {
    final tagName = releaseData['tag_name'];
    final body = releaseData['body'] ?? 'No changelog available.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Update Available!'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Version: $currentVersion'),
              Text('Latest Version: $tagName'),
              const SizedBox(height: 16),
              const Text('Changelog:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: MarkdownBody(data: body),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () => _launchUrl(_fdroidUrl),
            child: const Text('F-Droid'),
          ),
          FilledButton(
            onPressed: () => _launchUrl(_githubUrl),
            child: const Text('GitHub'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppLogger.log('UpdateService: Could not launch $url');
    }
  }
}
