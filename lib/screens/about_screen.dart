import 'package:flutter/material.dart';
import 'package:repertoire/models/contributor.dart';
import 'package:repertoire/services/contributor_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
            const Text('Version: 1.0.0'),
            const Text('License: Apache 2.0'),
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
                  MaterialPageRoute(builder: (context) => const CreditsScreen()),
                );
              },
              child: const Text('View Contributors'),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Source Code on GitHub'),
              onTap: () => launchUrl(Uri.parse('https://github.com/Adithya-Jayan/MyRepertoirApp/tree/v1.0.0')),
            ),
          ],
        ),
      ),
    );
  }
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributors'),
      ),
      body: FutureBuilder<List<Contributor>>(
        future: loadContributors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No contributors found.'));
          } else {
            final contributors = snapshot.data!;
            return ListView.builder(
              itemCount: contributors.length,
              itemBuilder: (context, index) {
                final c = contributors[index];
                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(c.avatarUrl)),
                  title: Text(c.login),
                  subtitle: Text('${c.contributions} contributions'),
                  onTap: () => launchUrl(Uri.parse(c.htmlUrl)),
                );
              },
            );
          }
        },
      ),
    );
  }
}
