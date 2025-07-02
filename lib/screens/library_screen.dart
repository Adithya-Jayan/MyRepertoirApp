import 'package:flutter/material.dart';
import '../models/music_piece.dart';
import '../database/music_piece_repository.dart';
import './add_edit_piece_screen.dart';
import './music_piece_card.dart';
import './tag_management_screen.dart';
import '../services/google_drive_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<MusicPiece> _musicPieces = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  Map<String, dynamic> _filterOptions = {};

  final GoogleDriveService _googleDriveService = GoogleDriveService();

  Future<void> _syncWithGoogleDrive() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing with Google Drive...')),
    );
    try {
      // Upload music piece metadata
      final musicPiecesJson = _musicPieces.map((piece) => piece.toJson()).toList();
      await _googleDriveService.uploadMusicPieces(jsonEncode(musicPiecesJson));

      // Upload media files
      for (var piece in _musicPieces) {
        for (var mediaItem in piece.mediaItems) {
          if (mediaItem.pathOrUrl.isNotEmpty && mediaItem.googleDriveFileId == null) {
            // Only upload if it's a local file and not already synced
            // A more robust check for local file paths might be needed depending on OS
            if (await File(mediaItem.pathOrUrl).exists()) {
              final uploadedFile = await _googleDriveService.uploadFileToDrive(mediaItem.pathOrUrl);
              if (uploadedFile != null && uploadedFile.id != null) {
                mediaItem.googleDriveFileId = uploadedFile.id;
                // Update the music piece in the database with the new mediaItem.googleDriveFileId
                await _repository.updateMusicPiece(piece);
              }
            }
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync complete!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  Future<void> _backupData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backing up data...')),
    );
    try {
      final musicPieces = await _repository.getMusicPieces();
      final jsonString = jsonEncode(musicPieces.map((e) => e.toJson()).toList());

      String? outputFile = await FilePicker.platform.saveFile(
        fileName: 'music_repertoire_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data backed up successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup cancelled.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _restoreData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring data...')),
    );
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> restoredData = jsonDecode(jsonString);

        final List<dynamic> musicPiecesJson = restoredData['musicPieces'] ?? [];
        final List<MusicPiece> restoredPieces = musicPiecesJson.map((e) => MusicPiece.fromJson(e)).toList();

        // Clear existing data and insert restored data
        await _repository.deleteAllMusicPieces();
        for (var piece in restoredPieces) {
          // Download associated media files from Google Drive if googleDriveFileId is present
          for (var mediaItem in piece.mediaItems) {
            if (mediaItem.googleDriveFileId != null && mediaItem.googleDriveFileId!.isNotEmpty) {
              final appDocDir = await getApplicationDocumentsDirectory();
              final mediaDir = Directory(p.join(appDocDir.path, 'repertoire_media'));
              if (!await mediaDir.exists()) {
                await mediaDir.create(recursive: true);
              }
              final localFilePath = p.join(mediaDir.path, p.basename(mediaItem.pathOrUrl));
              await _googleDriveService.downloadFileFromDrive(mediaItem.googleDriveFileId!, localFilePath);
              mediaItem.pathOrUrl = localFilePath; // Update local path
            }
          }
          await _repository.insertMusicPiece(piece);
        }
        _loadMusicPieces(); // Reload UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore cancelled.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMusicPieces();
  }

  Future<void> _loadMusicPieces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final pieces = await _repository.getMusicPieces();
      setState(() {
        _musicPieces = _filterMusicPieces(pieces);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load music pieces: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MusicPiece> _filterMusicPieces(List<MusicPiece> pieces) {
    return pieces.where((piece) {
      final titleMatch = _filterOptions['title'] == null ||
          piece.title.toLowerCase().contains(_filterOptions['title'].toLowerCase());
      final artistComposerMatch = _filterOptions['artistComposer'] == null ||
          piece.artistComposer.toLowerCase().contains(_filterOptions['artistComposer'].toLowerCase());
      final genreMatch = _filterOptions['genre'] == null ||
          piece.genre.any((g) => g.toLowerCase().contains(_filterOptions['genre'].toLowerCase()));
      final tagsMatch = _filterOptions['tags'] == null ||
          piece.tags.any((t) => t.toLowerCase().contains(_filterOptions['tags'].toLowerCase()));

      return titleMatch && artistComposerMatch && genreMatch && tagsMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search music pieces...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              // TODO: Implement search logic
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter Options'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Title'),
                          initialValue: _filterOptions['title'],
                          onChanged: (value) => _filterOptions['title'] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Artist/Composer'),
                          initialValue: _filterOptions['artistComposer'],
                          onChanged: (value) => _filterOptions['artistComposer'] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Genre'),
                          initialValue: _filterOptions['genre'],
                          onChanged: (value) => _filterOptions['genre'] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Tags'),
                          initialValue: _filterOptions['tags'],
                          onChanged: (value) => _filterOptions['tags'] = value,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadMusicPieces();
                      },
                      child: const Text('Apply Filter'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync), // Sync button
            onPressed: _syncWithGoogleDrive,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file), // Backup button
            onPressed: _backupData,
          ),
          IconButton(
            icon: const Icon(Icons.download), // Restore button
            onPressed: _restoreData,
          ),
          IconButton(
            icon: const Icon(Icons.tag),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TagManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _musicPieces.isEmpty
                  ? const Center(child: Text('No music pieces found. Add one!'))
                  : ListView.builder(
                      itemCount: _musicPieces.length,
                      itemBuilder: (context, index) {
                        return MusicPieceCard(piece: _musicPieces[index]);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditPieceScreen()),
          );
          _loadMusicPieces(); // Reload data after adding/editing
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
