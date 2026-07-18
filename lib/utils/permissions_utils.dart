import 'dart:io'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import for BuildContext, showDialog
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repertoire/utils/app_logger.dart';

import 'package:repertoire/l10n/l10n.dart';

/// Checks if the current build is the Google Play Store variant.
Future<bool> isPlayStoreBuild() async {
  if (kIsWeb) return false;
  if (!Platform.isAndroid) return false;
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.packageName.endsWith('.playstore');
  } catch (_) {
    return false;
  }
}

/// Requests necessary permissions for the application.
/// Handles storage permissions for Android and iOS.
Future<void> requestPermissions(BuildContext context) async {
  // Pass BuildContext
  AppLogger.log("Attempting to request permissions...");

  if (kIsWeb) {
    AppLogger.log("Platform is Web. Skipping permission requests.");
    return;
  }

  if (Platform.isAndroid) {
    AppLogger.log("Platform is Android.");

    if (await isPlayStoreBuild()) {
      AppLogger.log(
        "Play Store build detected. Skipping MANAGE_EXTERNAL_STORAGE.",
      );
      return;
    }

    var status = await Permission.manageExternalStorage.status;
    AppLogger.log("Current Manage External Storage status: $status");

    if (!status.isGranted) {
      if (!context.mounted) return; // Add mounted check before using context
      final bool? shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.storagePermissionNeeded),
          content: Text(context.l10n.storagePermissionExplanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.deny),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.grant),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        AppLogger.log("Requesting Manage External Storage permission...");
        status = await Permission.manageExternalStorage.request();
        AppLogger.log(
          "New Manage External Storage status after request: $status",
        );
        if (!status.isGranted) {
          AppLogger.log("Manage External Storage permission denied by user.");
        }
      } else {
        AppLogger.log(
          "Manage External Storage permission request skipped by user.",
        );
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
