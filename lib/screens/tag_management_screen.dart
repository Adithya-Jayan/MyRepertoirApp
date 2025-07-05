import 'package:flutter/material.dart';
import '../models/tag.dart';
import 'package:uuid/uuid.dart';
import '../database/music_piece_repository.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final _tagNameController = TextEditingController();
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await _repository.getTags();
    setState(() {
      _tags = tags;
    });
  }

  Future<void> _addTag() async {
    if (_tagNameController.text.isNotEmpty) {
      final newTag = Tag(id: const Uuid().v4(), name: _tagNameController.text);
      await _repository.insertTag(newTag);
      _loadTags(); // Reload tags after adding
      _tagNameController.clear();
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    await _repository.deleteTag(tag.id);
    _loadTags(); // Reload tags after deleting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagNameController,
                    decoration: const InputDecoration(labelText: 'New Tag Name'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  return ListTile(
                    title: Text(tag.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteTag(tag),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
