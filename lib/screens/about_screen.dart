import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Music Repertoire App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Version: 1.0.0'),
            Text('License: Apache 2.0'),
            SizedBox(height: 20),
            Text(
              'This app helps you organize your music pieces, attach various media types, and track practice sessions.',
            ),
            SizedBox(height: 20),
            Text('Credits:'),
            Text('- Developed by Gemini CLI'),
            Text('- Inspired by Mihon app'),
          ],
        ),
      ),
    );
  }
}
