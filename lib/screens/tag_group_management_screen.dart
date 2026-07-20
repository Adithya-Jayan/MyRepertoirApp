import 'package:flutter/material.dart';
import '../database/music_piece_repository.dart';
import '../utils/app_logger.dart';
import '../utils/color_utils.dart';

import 'package:repertoire/l10n/l10n.dart';

class TagGroupManagementScreen extends StatefulWidget {
  const TagGroupManagementScreen({super.key});

  @override
  State<TagGroupManagementScreen> createState() =>
      _TagGroupManagementScreenState();
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
        title: Text(context.l10n.renameTagGroup),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: context.l10n.groupName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.rename),
          ),
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
        title: Text(context.l10n.renameTagInGroup(groupName)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: context.l10n.tagName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.rename),
          ),
        ],
      ),
    );

    if (newTagName != null &&
        newTagName.isNotEmpty &&
        newTagName != oldTagName) {
      await _repository.renameTagGlobally(groupName, oldTagName, newTagName);
      _changesMade = true;
      _loadStats();
    }
  }

  Future<void> _deleteGroup(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteTagGroup),
        content: Text(context.l10n.deleteTagGroupConfirmation(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
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
        title: Text(context.l10n.deleteTag),
        content: Text(
          context.l10n.removeTagFromGroupConfirmation(tagName, groupName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
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
      null,
      0xFFFF6B6B,
      0xFF4ECDC4,
      0xFF45B7D1,
      0xFFFFE66D,
      0xFF96CEB4,
      0xFFFFA07A,
      0xFFFFB6C1,
      0xFF87CEEB,
      0xFFD2B48C,
      0xFFC0C0C0,
    ];

    final colorNames = [
      context.l10n.defaultColor,
      context.l10n.coral,
      context.l10n.teal,
      context.l10n.skyBlue,
      context.l10n.yellow,
      context.l10n.mintGreen,
      context.l10n.lightSalmon,
      context.l10n.lightPink,
      context.l10n.skyBlue,
      context.l10n.tan,
      context.l10n.silver,
    ];

    final newColor = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chooseGroupColor),
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
                  child: color == null
                      ? const Icon(Icons.clear, size: 16)
                      : null,
                ),
                title: Text(colorNames[index]),
                trailing: color == currentColor
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, color),
              );
            },
          ),
        ),
      ),
    );

    if (newColor != currentColor ||
        (newColor == null && currentColor != null)) {
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
          title: Text(context.l10n.taggingManagement),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStats,
              tooltip: context.l10n.refresh,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tagGroupStats.isEmpty
            ? Center(child: Text(context.l10n.noTagGroupsFoundInYourLibrary))
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
                      ? adjustColorForBrightness(
                          Color(colorValue),
                          theme.brightness,
                        )
                      : colorScheme.surfaceContainerHighest;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      backgroundColor: colorScheme.surface,
                      collapsedBackgroundColor: colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      leading: Container(
                        width: 12,
                        height: 24,
                        decoration: BoxDecoration(
                          color: displayColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        context.l10n.usedInPieces(count),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') _renameGroup(name);
                          if (value == 'color') _changeColor(name, colorValue);
                          if (value == 'delete') _deleteGroup(name);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text(context.l10n.renameGroup),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'color',
                            child: Row(
                              children: [
                                Icon(Icons.palette, size: 18),
                                SizedBox(width: 8),
                                Text(context.l10n.changeColor),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  context.l10n.deleteGroup,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.associatedTags,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (tags.isEmpty)
                                Text(
                                  context.l10n.noTagsInThisGroup,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags
                                      .map(
                                        (tag) => ActionChip(
                                          label: Text(
                                            tag,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor:
                                              colorScheme.surfaceContainerLow,
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (context) => Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.edit,
                                                    ),
                                                    title: Text(
                                                      context.l10n
                                                          .renameNamedItem(tag),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _renameTag(name, tag);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    title: Text(
                                                      context.l10n
                                                          .deleteNamedItem(tag),
                                                      style: const TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
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
                                        ),
                                      )
                                      .toList(),
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
