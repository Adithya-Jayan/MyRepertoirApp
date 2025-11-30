import 'package:flutter/material.dart'; // Import for BuildContext, showDialog
import 'package:permission_handler/permission_handler.dart';
import 'package:repertoire/utils/app_logger.dart';

/// Requests necessary permissions for the application.
/// Handles storage permissions for Android and iOS.
Future<void> requestPermissions(BuildContext context) async { // Pass BuildContext
  AppLogger.log("Attempting to request permissions...");
  if (Platform.isAndroid) {
    AppLogger.log("Platform is Android.");
    var status = await Permission.manageExternalStorage.status;
    AppLogger.log("Current Manage External Storage status: $status");

    if (!status.isGranted) {
      final bool? shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Permission Needed'),
          content: const Text(
            'This app needs "All files access" (Manage External Storage) '
            'to manage backups in your chosen external storage folder, '
            'and to access media files that you link from arbitrary locations. '
            'Without this, backup/restore and linking external media may not work correctly.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Deny'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Grant'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        AppLogger.log("Requesting Manage External Storage permission...");
        status = await Permission.manageExternalStorage.request();
        AppLogger.log("New Manage External Storage status after request: $status");
        if (!status.isGranted) {
          AppLogger.log("Manage External Storage permission denied by user.");
        }
      } else {
        AppLogger.log("Manage External Storage permission request skipped by user.");
      }
    } else {
      AppLogger.log("Manage External Storage permission already granted.");
    }
  } else if (Platform.isIOS) {
    AppLogger.log("Platform is iOS.");
    var status = await Permission.photos.status;
    AppLogger.log("Current Photos permission status: $status");
    if (!status.isGranted) {
      AppLogger.log("Requesting Photos permission...");
      status = await Permission.photos.request();
      AppLogger.log("New Photos permission status after request: $status");
      if (!status.isGranted) {
        AppLogger.log("Photos permission denied by user.");
      }
    } else {
      AppLogger.log("Photos permission already granted.");
    }
  }
}