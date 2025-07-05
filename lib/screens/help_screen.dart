import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: const SingleChildScrollView(
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
              'Q: How do I add a new music piece?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: Tap the floating action button (plus icon) on the main library screen and fill in the details.',
            ),
            SizedBox(height: 10),
            Text(
              'Q: How can I attach media to a music piece?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: When adding or editing a music piece, use the "Add Media" button to select the type of media you want to attach.',
            ),
            SizedBox(height: 10),
            Text(
              'Q: How do I track my practice sessions?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'A: On the music piece detail screen, enable "Practice Tracking" and then tap "Log Practice" to record a session.',
            ),
            SizedBox(height: 20),
            Text(
              'Need more help? Contact support at support@example.com',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
