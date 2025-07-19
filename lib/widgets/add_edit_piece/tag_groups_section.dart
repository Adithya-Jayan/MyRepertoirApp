import 'package:flutter/material.dart';
import '../../models/tag_group.dart';
import '../detail_widgets/tag_group_section.dart';

/// A widget that displays and manages tag groups for a music piece.
class TagGroupsSection extends StatelessWidget {
  final List<TagGroup> tagGroups;
  final List<String> allTagGroupNames;
  final Function(TagGroup, TagGroup) onUpdateTagGroup;
  final Function(TagGroup) onDeleteTagGroup;
  final Future<List<String>> Function(String) onGetAllTagsForTagGroup;
  final Function(int, int) onReorderTagGroups;
  final VoidCallback onAddTagGroup;

  const TagGroupsSection({
    super.key,
    required this.tagGroups,
    required this.allTagGroupNames,
    required this.onUpdateTagGroup,
    required this.onDeleteTagGroup,
    required this.onGetAllTagsForTagGroup,
    required this.onReorderTagGroups,
    required this.onAddTagGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tag Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAddTagGroup,
              tooltip: 'Add Tag Group',
            ),
          ],
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tagGroups.length,
          buildDefaultDragHandles: false,
          itemBuilder: (context, index) {
            final tagGroup = tagGroups[index];
            return TagGroupSection(
              key: ValueKey(tagGroup.id),
              tagGroup: tagGroup,
              index: index,
              allTagGroupNames: allTagGroupNames,
              onUpdateTagGroup: onUpdateTagGroup,
              onDeleteTagGroup: onDeleteTagGroup,
              onGetAllTagsForTagGroup: onGetAllTagsForTagGroup,
            );
          },
          onReorder: onReorderTagGroups,
        ),
      ],
    );
  }
} 