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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildCategoryHeader(theme, 'App Information', Icons.info_outline),
            _buildSettingsCard([
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Music Repertoire App',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Organize your music pieces, attach media, and track your practice journey.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                title: const Text('Version'),
                trailing: Text(_appVersion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const ListTile(
                title: Text('License'),
                trailing: Text('Apache 2.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]),

            const SizedBox(height: 16),
            _buildCategoryHeader(theme, 'Credits', Icons.people_outline),
            _buildSettingsCard([
              const ListTile(
                leading: Icon(Icons.person_outline, size: 20),
                title: Text('Developed by'),
                trailing: Text('Adithya Jayan', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ),
              const ListTile(
                leading: Icon(Icons.auto_awesome_outlined, size: 20),
                title: Text('Inspired by'),
                trailing: Text('Mihon', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ),
              const Divider(indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreditsScreen()),
                      );
                    },
                    icon: const Icon(Icons.group_outlined, size: 18),
                    label: const Text('View All Contributors'),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 16),
            _buildCategoryHeader(theme, 'Links', Icons.link_outlined),
            _buildSettingsCard([
              ListTile(
                leading: const Icon(Icons.public, color: Colors.blue),
                title: const Text('Website'),
                subtitle: const Text('adithyajayan.in/MyRepertoirApp/', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _launchUrl('https://adithyajayan.in/MyRepertoirApp/'),
              ),
              ListTile(
                leading: const Icon(Icons.android, color: Colors.green),
                title: const Text('F-Droid'),
                subtitle: const Text('f-droid.org/.../myrepertoirapp', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _launchUrl('https://f-droid.org/en/packages/io.github.adithya_jayan.myrepertoirapp.fdroid/'),
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.black),
                title: const Text('GitHub'),
                subtitle: const Text('github.com/.../MyRepertoirApp', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _launchUrl('https://github.com/Adithya-Jayan/MyRepertoirApp'),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildCategoryHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(children: children),
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
    return Scaffold(
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
      body: SafeArea(
        child: _contributors == null
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
      ),
    );
  }
}