import 'package:flutter/material.dart';
import 'package:repertoire/services/google_drive_service.dart';

/// A screen for managing Google Drive synchronization settings.
///
/// This screen allows users to sign in/out of Google Drive and initiate
/// data synchronization (backup/restore) with their Google Drive account.
class GoogleDriveSyncScreen extends StatefulWidget {
  const GoogleDriveSyncScreen({super.key});

  @override
  State<GoogleDriveSyncScreen> createState() => _GoogleDriveSyncScreenState();
}

/// The state class for [GoogleDriveSyncScreen].
/// Manages Google Drive authentication status and sync operations.
class _GoogleDriveSyncScreenState extends State<GoogleDriveSyncScreen> {
  final GoogleDriveService _googleDriveService = GoogleDriveService(); // Service for Google Drive interactions.
  String _authStatus = 'Checking status...'; // Current authentication status message.

  @override
  void initState() {
    super.initState();
    _checkSignInStatus(); // Check Google Drive sign-in status when the screen initializes.
  }

  /// Checks the current Google Drive sign-in status and updates the UI.
  Future<void> _checkSignInStatus() async {
    final isSignedIn = await _googleDriveService.isSignedIn(); // Check if the user is signed in.
    setState(() {
      _authStatus = isSignedIn ? 'Signed in' : 'Not signed in'; // Update authentication status message.
    });
  }

  /// Handles Google Drive sign-in and sign-out operations.
  ///
  /// If currently signed in, it signs out; otherwise, it initiates the sign-in flow.
  Future<void> _handleSignInSignOut() async {
    if (await _googleDriveService.isSignedIn()) {
      await _googleDriveService.signOut(); // Sign out if already signed in.
    } else {
      await _googleDriveService.signIn(); // Sign in if not signed in.
    }
    _checkSignInStatus(); // Update the UI after sign-in/sign-out.
  }

  /// Initiates the Google Drive data synchronization process.
  ///
  /// Displays snackbar messages for sync progress and results.
  Future<void> _initiateSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Initiating Google Drive sync...')), // Show message indicating sync initiation.
    );
    try {
      // This is a placeholder. In a real app, you'd implement full sync logic.
      // For now, we'll just call the placeholder sync method.
      await _googleDriveService.syncData(); // Call the Google Drive sync service.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync complete!')), // Show success message.
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')), // Show error message if sync fails.
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
