import 'package:flutter/material.dart';
import 'package:repertoire/models/contributor.dart';
import 'package:repertoire/services/contributor_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    return Scaffold(
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
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Source Code on GitHub'),
              onTap: () => launchUrl(Uri.parse('https://github.com/Adithya-Jayan/MyRepertoirApp/tree/v1.0.0')), // Launch GitHub URL.
            ),
          ],
        ),
      ),
    );
  }
}

/// A screen that displays a list of contributors to the project.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributors'), // Title of the Contributors screen.
      ),
      body: FutureBuilder<List<Contributor>>(
        future: loadContributors(), // Asynchronously load contributor data.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator.
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Display error message.
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No contributors found.')); // Message for no contributors.
          } else {
            final contributors = snapshot.data!;
            return ListView.builder(
              itemCount: contributors.length,
              itemBuilder: (context, index) {
                final c = contributors[index];
                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(c.avatarUrl)), // Contributor's avatar.
                  title: Text(c.login), // Contributor's login name.
                  subtitle: Text('${c.contributions} contributions'), // Number of contributions.
                  onTap: () => launchUrl(Uri.parse(c.htmlUrl)), // Open contributor's GitHub profile.
                );
              },
            );
          }
        },
      ),
    );
  }
}