import 'dart:io';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  // TODO: Replace with your actual credentials from the Google Cloud Console.
  // You will need to create OAuth 2.0 client IDs for Android, iOS, and Web.
  static const _clientId = 'YOUR_CLIENT_ID';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
    clientId: _clientId,
  );

  Future<drive.DriveApi?> _getDriveApi() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final headers = await googleUser.authHeaders;
    final client = GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  // ... (file operation methods will be added here later)

  Future<List<drive.File>> listFiles() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return [];
    }

    final fileList = await driveApi.files.list();
    return fileList.files ?? [];
  }

  Future<void> uploadMusicPieces(String jsonContent) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('Google Drive API not initialized.');
    }

    const fileName = 'music_repertoire_backup.json';
    drive.File? existingFile;

    // Check if the file already exists
    final fileList = await driveApi.files.list(q: 'name = "$fileName" and trashed = false');
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      existingFile = fileList.files!.first;
    }

    final contentBytes = utf8.encode(jsonContent);
    final media = drive.Media(Stream.fromIterable([contentBytes]), contentBytes.length);

    if (existingFile != null) {
      // Update existing file
      await driveApi.files.update(
        drive.File(),
        existingFile.id!,
        uploadMedia: media,
      );
    } else {
      // Create new file
      final fileMetadata = drive.File()
        ..name = fileName
        ..mimeType = 'application/json';
      await driveApi.files.create(fileMetadata, uploadMedia: media);
    }
  }

  Future<String?> downloadMusicPieces() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('Google Drive API not initialized.');
    }

    const fileName = 'music_repertoire_backup.json';
    final fileList = await driveApi.files.list(q: 'name = "$fileName" and trashed = false');

    if (fileList.files == null || fileList.files!.isEmpty) {
      return null; // No backup file found
    }

    final fileId = fileList.files!.first.id!;
    final response = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    final data = <int>[];
    await for (var chunk in response.stream) {
      data.addAll(chunk);
    }
    return utf8.decode(data);
  }

  Future<drive.File?> uploadFileToDrive(String filePath, {String? parentId}) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return null;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      print('File does not exist: $filePath');
      return null;
    }

    final fileMetadata = drive.File()
      ..name = p.basename(filePath);
    if (parentId != null) {
      fileMetadata.parents = [parentId];
    }

    final media = drive.Media(file.openRead(), file.lengthSync());

    try {
      final uploadedFile = await driveApi.files.create(fileMetadata, uploadMedia: media);
      return uploadedFile;
    } catch (e) {
      print('Error uploading file to Drive: $e');
      return null;
    }
  }

  Future<void> downloadFileFromDrive(String fileId, String savePath) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return;
    }

    try {
      final response = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final file = File(savePath);
      final sink = file.openWrite();
      await response.stream.pipe(sink);
      await sink.close();
    } catch (e) {
      print('Error downloading file from Drive: $e');
    }
  }

  Future<void> deleteFile(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      return;
    }

    await driveApi.files.delete(fileId);
  }
}

// A custom HTTP client that includes the access token in the headers.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
