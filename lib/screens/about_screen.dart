import 'package:flutter/material.dart';
import 'package:repertoire/models/contributor.dart';
import 'package:repertoire/services/contributor_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:repertoire/utils/app_logger.dart';

/// A screen that displays information about the application.
///
/// This includes the app version, license, credits, and a link to the source code.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

/// The state class for [AboutScreen].
/// Manages the display of app version and other static information.
class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = 'Loading...'; // Stores the application version.

  @override
  void initState() {
    super.initState();
    _loadAppVersion(); // Load the application version when the state initializes.
  }

  /// Asynchronously loads the application version from package info.
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform(); // Get package information.
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}'; // Set the app version string.
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('About'), // Title of the About screen.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Music Repertoire App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Version: $_appVersion'), // Display the app version.
            const Text('License: Apache 2.0'), // Display the app license.
            const SizedBox(height: 20),
            const Text(
              'This app helps you organize your music pieces, attach various media types, and track practice sessions.',
            ),
            const SizedBox(height: 20),
            const Text('Credits:'),
            const Text('- Developed by Adithya Jayan'),
            const Text('- Inspired by Mihon app'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreditsScreen()), // Navigate to the Credits screen.
                );
              },
              child: const Text('View Contributors'),
            ),
            const SizedBox(height: 20),
            // Replace the old ListTile with a nicer one
            ListTile(
              leading: Icon(Icons.code, color: Colors.blue),
              title: Text('Source Code on GitHub', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              subtitle: Text('https://github.com/Adithya-Jayan/MyRepertoirApp', style: TextStyle(fontSize: 12)),
              onTap: () async {
                final url = Uri.parse('https://github.com/Adithya-Jayan/MyRepertoirApp');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open the link.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A screen that displays a list of contributors to the project.
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  List<Contributor>? _contributors;
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _loadContributorsAndPreloadAvatars();
  }

  Future<void> _loadContributorsAndPreloadAvatars() async {
    try {
      final contributors = await loadContributors();
      setState(() {
        _contributors = contributors;
      });
      
      // Preload avatars in the background
      setState(() {
        _isPreloading = true;
      });
      
      // Download all avatars and refresh the page
      for (final contributor in contributors) {
        try {
          await ContributorImageCache.getCachedAvatarPath(contributor.login, contributor.avatarUrl);
          // Add a small delay to avoid overwhelming the network
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          AppLogger.log('Error downloading avatar for ${contributor.login}: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
        // Force a rebuild to show the downloaded avatars
        setState(() {});
      }
    } catch (e) {
      AppLogger.log('Error loading contributors: $e');
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Contributors'), // Title of the Contributors screen.
        actions: [
          if (_isPreloading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _contributors == null
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator.
          : _contributors!.isEmpty
              ? const Center(child: Text('No contributors found.')) // Message for no contributors.
              : ListView.builder(
                  itemCount: _contributors!.length,
                  itemBuilder: (context, index) {
                    final c = _contributors![index];
                    return FutureBuilder<String?>(
                      future: ContributorImageCache.getCachedAvatarPath(c.login, c.avatarUrl),
                      builder: (context, snapshot) {
                        Widget avatar;
                        if (snapshot.hasData && snapshot.data != null) {
                          // Use cached image
                          avatar = CircleAvatar(
                            backgroundImage: FileImage(File(snapshot.data!)),
                          );
                        } else {
                          // Fallback to network image or placeholder
                          avatar = CircleAvatar(
                            backgroundImage: NetworkImage(c.avatarUrl),
                            onBackgroundImageError: (exception, stackTrace) {
                              // Handle error by showing a placeholder
                            },
                          );
                        }
                        
                        return ListTile(
                          leading: GestureDetector(
                            onTap: () => launchUrl(Uri.parse(c.htmlUrl)), // Only avatar is clickable
                            child: avatar,
                          ),
                          title: Text(c.login), // Contributor's login name.
                          subtitle: Text('${c.contributions} contributions'), // Number of contributions.
                          // Removed onTap from ListTile to prevent accidental clicks
                        );
                      },
                    );
                  },
                ),
    );
  }
}