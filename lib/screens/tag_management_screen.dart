import 'package:flutter/material.dart';
import '../models/tag.dart';
import 'package:uuid/uuid.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final _tagNameController = TextEditingController();
  List<Tag> _tags = []; // TODO: Load from database

  void _addTag() {
    if (_tagNameController.text.isNotEmpty) {
      setState(() {
        _tags.add(Tag(id: const Uuid().v4(), name: _tagNameController.text));
        _tagNameController.clear();
        // TODO: Save to database
      });
    }
  }

  void _deleteTag(Tag tag) {
    setState(() {
      _tags.remove(tag);
      // TODO: Delete from database
    });
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
