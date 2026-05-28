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
  final Function(TagGroup, TagGroup, {bool isAutofill}) onUpdateTagGroup;
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
  TextEditingController? _addTagController;
  bool _isAddingTag = false;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    return Container(
      key: ValueKey(widget.tagGroup.id),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side: Management Rail
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  right: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Column(
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => widget.onDeleteTagGroup(widget.tagGroup),
                    tooltip: 'Delete tag group',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Name and Color Picker at Top
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            initialValue: TextEditingValue(text: widget.tagGroup.name),
                            fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                              _tagGroupController.addListener(() {
                                if (_tagGroupController.text != fieldTextEditingController.text) {
                                  fieldTextEditingController.text = _tagGroupController.text;
                                }
                              });
                              return TextFormField(
                                controller: fieldTextEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Group Name',
                                  isDense: true,
                                  border: UnderlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                onChanged: (value) {
                                  widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(name: value));
                                },
                                onFieldSubmitted: (value) async {
                                  widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(name: value));
                                  onFieldSubmitted();
                                  final mostCommonColor = await widget.onFetchMostCommonColor(value);
                                  if (mostCommonColor != null) {
                                    widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(color: mostCommonColor), isAutofill: true);
                                  }
                                },
                              );
                            },
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                              return widget.allTagGroupNames.where((option) =>
                                option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (selection) async {
                              _tagGroupController.text = selection;
                              widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(name: selection));
                              final mostCommonColor = await widget.onFetchMostCommonColor(selection);
                              if (mostCommonColor != null) {
                                widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(color: mostCommonColor), isAutofill: true);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Theme(
                          data: theme.copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: _buildColorDropdown(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tags Area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              ...widget.tagGroup.tags.map((tag) {
                                final color = widget.tagGroup.color != null ? Color(widget.tagGroup.color!) : null;
                                final tagColor = color != null ? adjustColorForBrightness(color, brightness) : null;
                                
                                return Chip(
                                  label: Text(tag, style: theme.textTheme.bodySmall),
                                  backgroundColor: tagColor,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.only(left: 8.0, right: 4.0),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () {
                                    final updatedTags = List<String>.from(widget.tagGroup.tags)..remove(tag);
                                    widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(tags: updatedTags));
                                  },
                                );
                              }),
                              
                              if (!_isAddingTag)
                                InkWell(
                                  onTap: () => setState(() => _isAddingTag = true),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 14, color: colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text('Add tag', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          if (_isAddingTag) ...[
                            const SizedBox(height: 12),
                            FutureBuilder<List<String>>(
                              future: widget.onGetAllTagsForTagGroup(widget.tagGroup.name),
                              builder: (context, snapshot) {
                                final availableTags = snapshot.data ?? [];
                                return Autocomplete<String>(
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                                    return availableTags.where((option) =>
                                      option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                  },
                                  onSelected: (selection) {
                                    if (!widget.tagGroup.tags.contains(selection)) {
                                      final updatedTags = List<String>.from(widget.tagGroup.tags)..add(selection);
                                      widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(tags: updatedTags));
                                    }
                                    _addTagController?.clear();
                                    setState(() => _isAddingTag = false);
                                  },
                                  fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                                    _addTagController = fieldTextEditingController;
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (_isAddingTag && !focusNode.hasFocus) focusNode.requestFocus();
                                    });

                                    return TextFormField(
                                      controller: fieldTextEditingController,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Tag name (or comma-separated list)',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                      onTapOutside: (_) {
                                        if (fieldTextEditingController.text.isEmpty) {
                                          setState(() => _isAddingTag = false);
                                        }
                                      },
                                      onFieldSubmitted: (value) {
                                        if (value.isNotEmpty) {
                                          final tagsToAdd = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                          final updatedTags = List<String>.from(widget.tagGroup.tags)..addAll(tagsToAdd);
                                          widget.onUpdateTagGroup(widget.tagGroup, widget.tagGroup.copyWith(tags: updatedTags));
                                        }
                                        fieldTextEditingController.clear();
                                        setState(() => _isAddingTag = false);
                                        onFieldSubmitted();
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}