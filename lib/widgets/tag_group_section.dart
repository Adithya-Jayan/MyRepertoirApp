import 'package:flutter/material.dart';
import 'package:repertoire/models/tag_group.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(tagGroup.id),
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
                            return allTagGroupNames.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            onUpdateTagGroup(tagGroup, tagGroup.copyWith(name: selection));
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(labelText: 'Tag Group Name'),
                              onChanged: (value) {
                                // This is a temporary update, the final update is on submit
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
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDeleteTagGroup(tagGroup),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: tagGroup.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
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
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Add new tag'),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            final tagsToAdd = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                            final updatedTags = List<String>.from(tagGroup.tags)..addAll(tagsToAdd);
                            onUpdateTagGroup(tagGroup, tagGroup.copyWith(tags: updatedTags));
                          }
                          textEditingController.clear();
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
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
