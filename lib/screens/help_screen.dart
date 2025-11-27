import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A screen that provides help information and answers to frequently asked questions.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'), // Updated title for the Help screen.
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 10),
            Text(
              'Q: How do I quickly find a specific music piece?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: Use the search bar at the top of the main library screen. You can search by title, artist/composer (Subtitle), or tags.',
            ),
            SizedBox(height: 10),
            Text(
              'Q: Can I organize my music pieces into custom categories?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: Yes, navigate to Settings > Groups to create, edit, and manage your custom groups. You can assign pieces to multiple groups.',
            ),
            SizedBox(height: 10),
            Text(
              'Q: How do I change the app\'s appearance (theme, colors)?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: Go to Settings > Personalization. Here you can switch between light/dark/system themes and choose an accent color.',
            ),
            SizedBox(height: 10),
            Text(
              'Q: Is there a way to backup my data?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: Yes, visit Settings > Backup & Restore. You can perform manual backups or set up automatic backups to your local storage.',
            ),
            SizedBox(height: 10),
            Text(
              'Q: How can I reorder media items or tag groups within a music piece?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: On the Add/Edit Piece screen, long-press and drag the media items or tag groups to reorder them.',
            ),
            SizedBox(height: 20),
            Text(
              'Need more help? Visit our website or GitHub repository:',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blue),
              title: const Text('Website & Documentation', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              subtitle: const Text('https://adithyajayan.in/MyRepertoirApp/', style: TextStyle(fontSize: 12)),
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final url = Uri.parse('https://adithyajayan.in/MyRepertoirApp/');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Could not open the link.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.black),
              title: const Text('Source Code on GitHub', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              subtitle: const Text('https://github.com/Adithya-Jayan/MyRepertoirApp', style: TextStyle(fontSize: 12)),
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final url = Uri.parse('https://github.com/Adithya-Jayan/MyRepertoirApp');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Could not open the link.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
    );
  }
}