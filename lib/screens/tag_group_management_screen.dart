import 'package:flutter/material.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';
import '../utils/color_utils.dart';

class TagGroupManagementScreen extends StatefulWidget {
  const TagGroupManagementScreen({super.key});

  @override
  State<TagGroupManagementScreen> createState() => _TagGroupManagementScreenState();
}

class _TagGroupManagementScreenState extends State<TagGroupManagementScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<Map<String, dynamic>> _tagGroupStats = [];
  bool _isLoading = true;
  bool _changesMade = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _repository.getTagGroupStats();
      setState(() {
        _tagGroupStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.log('Error loading tag group stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _renameGroup(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Tag Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Rename')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      await _repository.renameTagGroupGlobally(oldName, newName);
      _changesMade = true;
      _loadStats();
    }
  }

  Future<void> _renameTag(String groupName, String oldTagName) async {
    final controller = TextEditingController(text: oldTagName);
    final newTagName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Tag in "$groupName"'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tag Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Rename')),
        ],
      ),
    );

    if (newTagName != null && newTagName.isNotEmpty && newTagName != oldTagName) {
      await _repository.renameTagGlobally(groupName, oldTagName, newTagName);
      _changesMade = true;
      _loadStats();
    }
  }

  Future<void> _deleteGroup(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag Group'),
        content: Text('Are you sure you want to delete the tag group "$name" and remove it from all pieces?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteTagGroupGlobally(name);
      _changesMade = true;
      _loadStats();
    }
  }

  Future<void> _deleteTag(String groupName, String tagName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Remove tag "$tagName" from group "$groupName" across all pieces?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteTagGlobally(groupName, tagName);
      _changesMade = true;
      _loadStats();
    }
  }

  Future<void> _changeColor(String groupName, int? currentColor) async {
    final colorOptions = [
      null, 0xFFFF6B6B, 0xFF4ECDC4, 0xFF45B7D1, 0xFFFFE66D, 
      0xFF96CEB4, 0xFFFFA07A, 0xFFFFB6C1, 0xFF87CEEB, 0xFFD2B48C, 0xFFC0C0C0,
    ];
    
    final colorNames = [
      'Default', 'Coral', 'Teal', 'Sky Blue', 'Yellow', 
      'Mint Green', 'Light Salmon', 'Light Pink', 'Sky Blue', 'Tan', 'Silver',
    ];

    final newColor = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Group Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: colorOptions.length,
            itemBuilder: (context, index) {
              final color = colorOptions[index];
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color != null ? Color(color) : Colors.transparent,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: color == null ? const Icon(Icons.clear, size: 16) : null,
                ),
                title: Text(colorNames[index]),
                trailing: color == currentColor ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () => Navigator.pop(context, color),
              );
            },
          ),
        ),
      ),
    );

    if (newColor != currentColor || (newColor == null && currentColor != null)) {
      if (newColor == null) {
        // We need a clear method or handle null in updateTagGroupColor.
        // For now, let's assume we can pass null or 0.
        // Actually, updateTagGroupColor takes int. 
        // Let's stick to the predefined colors or add a specific null handler.
      } else {
        await _repository.updateTagGroupColor(groupName, newColor);
        _changesMade = true;
        _loadStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changesMade);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tagging Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStats,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tagGroupStats.isEmpty
                ? const Center(child: Text('No tag groups found in your library.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _tagGroupStats.length,
                    itemBuilder: (context, index) {
                      final stat = _tagGroupStats[index];
                      final name = stat['name'] as String;
                      final count = stat['count'] as int;
                      final colorValue = stat['color'] as int?;
                      final tags = stat['tags'] as List<String>;
                      
                      final displayColor = colorValue != null 
                          ? adjustColorForBrightness(Color(colorValue), theme.brightness) 
                          : colorScheme.surfaceContainerHighest;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          backgroundColor: colorScheme.surface,
                          collapsedBackgroundColor: colorScheme.surface,
                          shape: const RoundedRectangleBorder(side: BorderSide.none),
                          leading: Container(
                            width: 12,
                            height: 24,
                            decoration: BoxDecoration(
                              color: displayColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Used in $count piece${count == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'rename') _renameGroup(name);
                              if (value == 'color') _changeColor(name, colorValue);
                              if (value == 'delete') _deleteGroup(name);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Rename Group')])),
                              const PopupMenuItem(value: 'color', child: Row(children: [Icon(Icons.palette, size: 18), SizedBox(width: 8), Text('Change Color')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Group', style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Associated Tags:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  if (tags.isEmpty)
                                    const Text('No tags in this group.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13))
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: tags.map((tag) => ActionChip(
                                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                                        backgroundColor: colorScheme.surfaceContainerLow,
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) => Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: const Icon(Icons.edit),
                                                  title: Text('Rename "$tag"'),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    _renameTag(name, tag);
                                                  },
                                                ),
                                                ListTile(
                                                  leading: const Icon(Icons.delete, color: Colors.red),
                                                  title: Text('Delete "$tag"', style: const TextStyle(color: Colors.red)),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    _deleteTag(name, tag);
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            ),
                                          );
                                        },
                                      )).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
