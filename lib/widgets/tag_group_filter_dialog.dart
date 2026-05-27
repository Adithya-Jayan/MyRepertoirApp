import 'package:flutter/material.dart';

class TagGroupFilterDialog extends StatefulWidget {
  final Map<String, List<String>> availableTags;
  final Map<String, List<String>> initialSelectedTags;

  const TagGroupFilterDialog({
    super.key,
    required this.availableTags,
    required this.initialSelectedTags,
  });

  @override
  State<TagGroupFilterDialog> createState() => _TagGroupFilterDialogState();
}

class _TagGroupFilterDialogState extends State<TagGroupFilterDialog> {
  late Map<String, List<String>> _selectedTags;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Deep copy the initial selected tags to avoid modifying the original lists
    _selectedTags = widget.initialSelectedTags.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  List<String> _getFilteredTags(String tagName, List<String> tags) {
    if (_searchQuery.isEmpty) {
      return tags;
    }
    return tags
        .where((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedTagSetNames = widget.availableTags.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 20),
          const SizedBox(width: 8),
          const Text('Filter by Tags'),
          const Spacer(),
          if (_selectedTags.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
              child: const Text('Clear All', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tags...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: sortedTagSetNames.length,
                itemBuilder: (context, index) {
                  final tagSetName = sortedTagSetNames[index];
                  final tags = widget.availableTags[tagSetName]!;
                  final filteredTags = _getFilteredTags(tagSetName, tags);

                  if (filteredTags.isEmpty && _searchQuery.isNotEmpty) {
                    return const SizedBox.shrink();
                  }

                  final selectedInSet = _selectedTags[tagSetName] ?? [];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                    ),
                    child: ExpansionTile(
                      title: Text(tagSetName, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: selectedInSet.isNotEmpty 
                        ? Text('${selectedInSet.length} selected', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12))
                        : null,
                      shape: const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      children: filteredTags.map((tag) {
                        final isSelected = selectedInSet.contains(tag);
                        return CheckboxListTile(
                          title: Text(tag, style: const TextStyle(fontSize: 14)),
                          value: isSelected,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedTags.putIfAbsent(tagSetName, () => []).add(tag);
                              } else {
                                _selectedTags[tagSetName]?.remove(tag);
                                if (_selectedTags[tagSetName]?.isEmpty ?? false) {
                                  _selectedTags.remove(tagSetName);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedTags),
          child: const Text('Apply Filters'),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}