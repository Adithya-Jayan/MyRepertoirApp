import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../utils/app_logger.dart';

class GroupDialogManager {
  /// Prompts the user to add a new group.
  ///
  /// Opens an AlertDialog for the user to enter a new group name.
  /// Returns the new group name if provided, null otherwise.
  static Future<String?> showAddGroupDialog(BuildContext context) async {
    String newGroupName = '';
    final bool? groupAdded = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Group'),
        content: TextField(
          onChanged: (value) {
            newGroupName = value;
          },
          decoration: const InputDecoration(hintText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newGroupName.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (groupAdded == true) {
      AppLogger.log('GroupDialogManager: User added group: $newGroupName');
      return newGroupName;
    }
    return null;
  }

  /// Prompts the user to edit an existing group's name.
  ///
  /// Opens an AlertDialog with the current group name for editing.
  /// Returns the edited group name if provided, null otherwise.
  static Future<String?> showEditGroupDialog(BuildContext context, Group group) async {
    String editedGroupName = group.name;
    final bool? groupEdited = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: TextEditingController(text: group.name),
          onChanged: (value) {
            editedGroupName = value;
          },
          decoration: const InputDecoration(hintText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (editedGroupName.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (groupEdited == true) {
      AppLogger.log('GroupDialogManager: User edited group: $editedGroupName');
      return editedGroupName;
    }
    return null;
  }

  /// Prompts the user to confirm deletion of a group.
  ///
  /// Returns true if the user confirms deletion, false otherwise.
  static Future<bool> showDeleteGroupDialog(BuildContext context, Group group) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete the group "${group.name}"?\n\n'
          'Music pieces associated ONLY with this group will be moved to the "Default Group".'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      AppLogger.log('GroupDialogManager: User confirmed deletion of group: ${group.name}');
    }
    return confirmDelete ?? false;
  }
} 