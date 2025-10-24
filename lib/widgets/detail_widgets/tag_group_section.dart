import 'package:flutter/material.dart';
import 'package:repertoire/models/tag_group.dart';
import 'package:repertoire/utils/color_utils.dart';
import 'package:repertoire/utils/app_logger.dart';

/// A widget for displaying and editing a single TagGroup.
///
/// Allows users to modify the tag group's name, color, and associated tags.
class TagGroupSection extends StatefulWidget {
  final TagGroup tagGroup;
  final int index;
  final List<String> allTagGroupNames;
  final Function(TagGroup, TagGroup) onUpdateTagGroup;
  final Function(TagGroup) onDeleteTagGroup;
  final Future<List<String>> Function(String) onGetAllTagsForTagGroup;
  final Future<int?> Function(String) onFetchMostCommonColor;


  const TagGroupSection({
    super.key,
    required this.tagGroup,
    required this.index,
    required this.allTagGroupNames,
    required this.onUpdateTagGroup,
    required this.onDeleteTagGroup,
    required this.onGetAllTagsForTagGroup,
    required this.onFetchMostCommonColor,
  });

  @override
  State<TagGroupSection> createState() => _TagGroupSectionState();
}

class _TagGroupSectionState extends State<TagGroupSection> {
  late final TextEditingController _tagGroupController;

  @override
  void initState() {
    super.initState();
    _tagGroupController = TextEditingController(text: widget.tagGroup.name);
  }

  @override
  void dispose() {
    _tagGroupController.dispose();
    super.dispose();
  }

  static const List<int?> _colorOptions = [
    null, // Default (no color)
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

  static const List<String> _colorNames = [
    'Default',
    'Coral',
    'Teal',
    'Sky Blue',
    'Yellow',
    'Mint Green',
    'Light Salmon',
    'Light Pink',
    'Sky Blue',
    'Tan',
    'Silver',
  ];

  Widget _buildColorDropdown() {
    // Get the current color options, ensuring the current color is included
    final currentColor = widget.tagGroup.color;
    final colorOptions = List<int?>.from(_colorOptions);
    
    // If the current color is not null and not in our predefined list, add it
    if (currentColor != null && !colorOptions.contains(currentColor)) {
      colorOptions.add(currentColor);
    }
    
    // Use the current color directly (null is handled by the dropdown)
    final dropdownValue = currentColor;
    
    return DropdownButton<int?>(
      value: dropdownValue,
      onChanged: (int? newColor) {
        AppLogger.log('TagGroupSection: Color dropdown changed from ${widget.tagGroup.color} to $newColor');
        
        // Use different copyWith methods based on whether we're setting to null or a color
        final updatedTagGroup = newColor == null 
            ? widget.tagGroup.copyWithColorNull()
            : widget.tagGroup.copyWith(color: newColor);
            
        widget.onUpdateTagGroup(widget.tagGroup, updatedTagGroup);
      },
      items: colorOptions.asMap().entries.map((entry) {
        final color = entry.value;
        String colorName;
        
        // Find the name for this color
        if (color == null) {
          colorName = 'Default';
        } else {
          final predefinedIndex = _colorOptions.indexOf(color);
          colorName = predefinedIndex >= 0 ? _colorNames[predefinedIndex] : 'Custom Color';
        }
        
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
              Text(colorName),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Card(
      key: ValueKey(widget.tagGroup.id), // Unique key for ReorderableListView.
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
                          initialValue: TextEditingValue(text: widget.tagGroup.name),
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            // This is a workaround to sync the parent controller with the field's controller
                            _tagGroupController.addListener(() {
                              if (_tagGroupController.text != fieldTextEditingController.text) {
                                fieldTextEditingController.text = _tagGroupController.text;
                              }
                            });
                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(labelText: 'Tag Group Name'),
                              onChanged: (value) {
                                // Update the tag group name immediately as user types
                                widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(name: value));
                              },
                              onFieldSubmitted: (value) async {
                                widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(name: value));
                                onFieldSubmitted();
                                final mostCommonColor = await widget.onFetchMostCommonColor(value);
                                if (mostCommonColor != null) {
                                  widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(color: mostCommonColor));
                                }
                              },
                            );
                          },
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            // Provide tag group name suggestions based on user input.
                            return widget.allTagGroupNames.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) async {
                            // Update the tag group name when a suggestion is selected.
                            _tagGroupController.text = selection;
                            widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(name: selection));
                            final mostCommonColor = await widget.onFetchMostCommonColor(selection);
                            if (mostCommonColor != null) {
                              widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(color: mostCommonColor));
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete), // Button to delete the tag group.
                        onPressed: () => widget.onDeleteTagGroup(widget.tagGroup),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Text('Color:'),
                      const SizedBox(width: 8.0),
                      _buildColorDropdown(),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: widget.tagGroup.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: () {
                          final color = widget.tagGroup.color != null ? Color(widget.tagGroup.color!) : null;
                          return color != null ? adjustColorForBrightness(color, brightness) : null;
                        }(),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          final updatedTags = List<String>.from(widget.tagGroup.tags);
                          updatedTags.remove(tag);
                          widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(tags: updatedTags));
                        },
                      );
                    }).toList(),
                  ),
                  FutureBuilder<List<String>>(
                    future: widget.onGetAllTagsForTagGroup(widget.tagGroup.name),
                    builder: (context, snapshot) {
                      final availableTags = snapshot.data ?? [];
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          // Provide tag suggestions based on the selected tag group.
                          return availableTags.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          if (!widget.tagGroup.tags.contains(selection)) {
                            final updatedTags = List<String>.from(widget.tagGroup.tags)..add(selection);
                            widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(tags: updatedTags));
                          }
                        },
                        fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                          return TextFormField(
                            controller: fieldTextEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Add new tag'),
                            onFieldSubmitted: (value) {
                              if (value.isNotEmpty) {
                                final tagsToAdd = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                final updatedTags = List<String>.from(widget.tagGroup.tags)..addAll(tagsToAdd);
                                widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(tags: updatedTags));
                              }
                              fieldTextEditingController.clear(); // Clear the text field after submission.
                              onFieldSubmitted();
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: widget.index,
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