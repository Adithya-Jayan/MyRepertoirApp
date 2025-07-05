import 'package:flutter/material.dart';
import 'package:repertoire/services/google_drive_service.dart';

class GoogleDriveSyncScreen extends StatefulWidget {
  const GoogleDriveSyncScreen({super.key});

  @override
  State<GoogleDriveSyncScreen> createState() => _GoogleDriveSyncScreenState();
}

class _GoogleDriveSyncScreenState extends State<GoogleDriveSyncScreen> {
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  String _authStatus = 'Checking status...';

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    final isSignedIn = await _googleDriveService.isSignedIn();
    setState(() {
      _authStatus = isSignedIn ? 'Signed in' : 'Not signed in';
    });
  }

  Future<void> _handleSignInSignOut() async {
    if (await _googleDriveService.isSignedIn()) {
      await _googleDriveService.signOut();
    } else {
      await _googleDriveService.signIn();
    }
    _checkSignInStatus();
  }

  Future<void> _initiateSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Initiating Google Drive sync...')),
    );
    try {
      // This is a placeholder. In a real app, you'd implement full sync logic.
      // For now, we'll just call the placeholder sync method.
      await _googleDriveService.syncData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync complete!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Sync'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Authentication Status: $_authStatus'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleSignInSignOut,
              child: Text(_authStatus == 'Signed in' ? 'Sign out from Google Drive' : 'Sign in to Google Drive'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initiateSync,
              child: const Text('Initiate Sync (Backup/Restore)'),
            ),
          ],
        ),
      ),
    );
  }
}
