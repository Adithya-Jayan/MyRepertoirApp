import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../models/music_piece.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../models/media_type.dart';

class AddEditPieceScreen extends StatefulWidget {
  final MusicPiece? musicPiece;

  const AddEditPieceScreen({super.key, this.musicPiece});

  @override
  State<AddEditPieceScreen> createState() => _AddEditPieceScreenState();
}

class _AddEditPieceScreenState extends State<AddEditPieceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistComposerController = TextEditingController();
  final _genreController = TextEditingController();
  final _instrumentationController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _tagsController = TextEditingController();

  List<MediaItem> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.musicPiece != null) {
      _titleController.text = widget.musicPiece!.title;
      _artistComposerController.text = widget.musicPiece!.artistComposer;
      _genreController.text = widget.musicPiece!.genre.join(', ');
      _instrumentationController.text = widget.musicPiece!.instrumentation;
      _difficultyController.text = widget.musicPiece!.difficulty;
      _tagsController.text = widget.musicPiece!.tags.join(', ');
      _mediaItems = List.from(widget.musicPiece!.mediaItems);
    }
  }

  Future<void> _pickFile(MediaType type) async {
    FilePickerResult? result;
    if (type == MediaType.image) {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } else if (type == MediaType.pdf) {
      result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    } else if (type == MediaType.audio) {
      result = await FilePicker.platform.pickFiles(type: FileType.audio);
    } else if (type == MediaType.videoLink) {
      // For video links, we don't pick a file, but rather expect a URL input.
      // This case will be handled by a simple text input.
      return;
    } else if (type == MediaType.markdown) {
      result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['md', 'txt']);
    }

    if (result != null && result.files.single.path != null) {
      setState(() {
        _mediaItems.add(MediaItem(
          id: const Uuid().v4(),
          type: type,
          pathOrUrl: result!.files.single.path!,
        ));
      });
    }
  }

  void _addMediaItem(MediaType type) {
    if (type == MediaType.videoLink || type == MediaType.markdown) {
      setState(() {
        _mediaItems.add(MediaItem(
          id: const Uuid().v4(),
          type: type,
          pathOrUrl: '',
        ));
      });
    } else {
      _pickFile(type);
    }
  }

  void _removeMediaItem(MediaItem item) {
    setState(() {
      _mediaItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Piece'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: Save the piece
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _artistComposerController,
                decoration: const InputDecoration(
                  labelText: 'Artist/Composer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre (comma-separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _instrumentationController,
                decoration: const InputDecoration(
                  labelText: 'Instrumentation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _difficultyController,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text('Media Attachments', style: Theme.of(context).textTheme.headlineSmall),
              ..._mediaItems.map((item) {
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item.pathOrUrl,
                        decoration: InputDecoration(labelText: '${item.type.name} Path/URL'),
                        onChanged: (value) => item.pathOrUrl = value,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeMediaItem(item),
                    ),
                  ],
                );
              }).toList(),
              FilledButton.tonal(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: MediaType.values.map((type) {
                        return ListTile(
                          title: Text('Add ${type.name}'),
                          onTap: () {
                            _addMediaItem(type);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
                child: const Text('Add Media'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
