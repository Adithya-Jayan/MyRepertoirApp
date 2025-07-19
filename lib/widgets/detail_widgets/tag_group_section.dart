import 'package:flutter/material.dart';
import 'package:repertoire/models/tag_group.dart';
import 'package:repertoire/utils/color_utils.dart';

/// A widget for displaying and editing a single TagGroup.
///
/// Allows users to modify the tag group's name, color, and associated tags.
class TagGroupSection extends StatelessWidget {
  final TagGroup tagGroup;
  final int index;
  final List<String> allTagGroupNames;
  final Function(TagGroup, TagGroup) onUpdateTagGroup;
  final Function(TagGroup) onDeleteTagGroup;
  final Future<List<String>> Function(String) onGetAllTagsForTagGroup;

  const TagGroupSection({
    super.key,
    required this.tagGroup,
    required this.index,
    required this.allTagGroupNames,
    required this.onUpdateTagGroup,
    required this.onDeleteTagGroup,
    required this.onGetAllTagsForTagGroup,
  });

  static const List<int?> _colorOptions = [
    null, // No color option
    0xFFFF6B6B, // Coral
    0xFF4ECDC4, // Teal
    0xFF45B7D1, // Sky Blue
    0xFFFFE66D, // Yellow
    0xFF96CEB4, // Mint Green
    0xFFFFA07A, // Light Salmon
    0xFFFFB6C1, // Light Pink
    0xFF87CEEB, // Sky Blue
    0xFFD2B48C, // Tan
    0xFFC0C0C0, // Silver
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Card(
      key: ValueKey(tagGroup.id), // Unique key for ReorderableListView.
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Autocomplete<String>(
                          initialValue: TextEditingValue(text: tagGroup.name),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<String>.empty();
                            }
                            // Provide tag group name suggestions based on user input.
                            return allTagGroupNames.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            // Update the tag group name when a suggestion is selected.
                            onUpdateTagGroup(tagGroup, tagGroup.copyWith(name: selection));
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            // Use the provided fieldTextEditingController for the TextFormField.
                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(labelText: 'Tag Group Name'),
                              onChanged: (value) {
                                // This is a temporary update, the final update is on submit
                                // The actual state update happens on onFieldSubmitted or onSelected
                              },
                              onFieldSubmitted: (value) {
                                onUpdateTagGroup(tagGroup, tagGroup.copyWith(name: value));
                                onFieldSubmitted();
                              },
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete), // Button to delete the tag group.
                        onPressed: () => onDeleteTagGroup(tagGroup),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Text('Color:'),
                      const SizedBox(width: 8.0),
                      DropdownButton<int?>(
                        value: _colorOptions.contains(tagGroup.color) 
                            ? tagGroup.color 
                            : null,
                        onChanged: (int? newColor) {
                          onUpdateTagGroup(tagGroup, tagGroup.copyWith(color: newColor));
                        },
                        items: _colorOptions.map((color) {
                          return DropdownMenuItem<int?>(
                            value: color,
                            child: Row(
                              children: [
                                if (color != null)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Color(color),
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.clear, size: 12),
                                  ),
                                const SizedBox(width: 8),
                                Text(color != null ? 'Color' : 'No Color'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tagGroup.tags.map((tag) {
                      final color = tagGroup.color != null ? Color(tagGroup.color!) : null;
                      return Chip(
                        label: Text(tag),
                        backgroundColor: color != null ? adjustColorForBrightness(color, brightness) : null,
                        onDeleted: () {
                          final updatedTags = List<String>.from(tagGroup.tags)..remove(tag);
                          onUpdateTagGroup(tagGroup, tagGroup.copyWith(tags: updatedTags));
                        },
                      );
                    }).toList(),
                  ),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      // Provide tag suggestions based on the selected tag group.
                      final tags = await onGetAllTagsForTagGroup(tagGroup.name);
                      return tags.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      if (!tagGroup.tags.contains(selection)) {
                        final updatedTags = List<String>.from(tagGroup.tags)..add(selection);
                        onUpdateTagGroup(tagGroup, tagGroup.copyWith(tags: updatedTags));
                      }
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      // Use the provided fieldTextEditingController for the TextFormField.
                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Add new tag'),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            final tagsToAdd = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                            final updatedTags = List<String>.from(tagGroup.tags)..addAll(tagsToAdd);
                            onUpdateTagGroup(tagGroup, tagGroup.copyWith(tags: updatedTags));
                          }
                          fieldTextEditingController.clear(); // Clear the text field after submission.
                          onFieldSubmitted();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.drag_handle), // Drag handle for reordering.
              ),
            ),
          ],
        ),
      ),
    );
  }
}