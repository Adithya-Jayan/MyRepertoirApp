import 'package:flutter/material.dart';
import '../../models/group.dart';

/// A widget that displays and manages group selection for a music piece.
class GroupsSection extends StatelessWidget {
  final List<Group> availableGroups;
  final Set<String> selectedGroupIds;
  final ValueChanged<Set<String>> onGroupIdsChanged;

  const GroupsSection({
    super.key,
    required this.availableGroups,
    required this.selectedGroupIds,
    required this.onGroupIdsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Groups'),
      initiallyExpanded: false,
      children: [
        ...availableGroups.map((group) {
          return CheckboxListTile(
            title: Text(group.name),
            value: selectedGroupIds.contains(group.id),
            onChanged: (bool? value) {
              final newSelectedGroupIds = Set<String>.from(selectedGroupIds);
              if (value == true) {
                newSelectedGroupIds.add(group.id);
              } else {
                newSelectedGroupIds.remove(group.id);
              }
              onGroupIdsChanged(newSelectedGroupIds);
            },
          );
        }),
      ],
    );
  }
} 