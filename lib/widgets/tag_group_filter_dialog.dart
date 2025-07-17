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
    _selectedTags = Map.from(widget.initialSelectedTags);
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
    final sortedTagSetNames = widget.availableTags.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return AlertDialog(
      title: const Text('Filter by Ordered Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Tags',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedTagSetNames.length,
                itemBuilder: (context, index) {
                  final tagSetName = sortedTagSetNames[index];
                  final tags = widget.availableTags[tagSetName]!;
                  final filteredTags = _getFilteredTags(tagSetName, tags);

                  if (filteredTags.isEmpty && _searchQuery.isNotEmpty) {
                    return const SizedBox.shrink(); // Hide if no matching tags
                  }

                  return ExpansionTile(
                    title: Text(tagSetName),
                    children: filteredTags.map((tag) {
                      final isSelected = _selectedTags[tagSetName]?.contains(tag) ?? false;
                      return CheckboxListTile(
                        title: Text(tag),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedTags
                                  .putIfAbsent(tagSetName, () => [])
                                  .add(tag);
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null); // Return null on cancel
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedTags);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}