import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:repertoire/utils/app_logger.dart';

Future<void> requestPermissions() async {
  AppLogger.log("Attempting to request permissions...");
  if (Platform.isAndroid) {
    AppLogger.log("Platform is Android.");
    var status = await Permission.manageExternalStorage.status;
    AppLogger.log("Current Manage External Storage status: $status");
    if (!status.isGranted) {
      AppLogger.log("Requesting Manage External Storage permission...");
      status = await Permission.manageExternalStorage.request();
      AppLogger.log("New Manage External Storage status after request: $status");
      if (!status.isGranted) {
        AppLogger.log("Manage External Storage permission denied by user.");
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
