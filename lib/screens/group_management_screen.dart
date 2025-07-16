import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/group.dart';
import 'package:uuid/uuid.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  List<Group> _groups = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  /// Loads all groups from the database and shared preferences.
  ///
  /// This method fetches all user-created groups from the database and
  /// loads the settings for the special "All" and "Ungrouped" groups from
  /// shared preferences. It then combines and sorts them for display.
  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final allDbGroups = await _repository.getGroups();

      // Get stored settings for special groups, with default values
      final allGroupOrder = prefs.getInt('all_group_order') ?? -2;
      final allGroupIsHidden = prefs.getBool('all_group_isHidden') ?? false;
      final ungroupedGroupOrder = prefs.getInt('ungrouped_group_order') ?? -1;
      final ungroupedGroupIsHidden = prefs.getBool('ungrouped_group_isHidden') ?? false;

      final allGroup = Group(
        id: 'all_group',
        name: 'All',
        order: allGroupOrder,
        isHidden: allGroupIsHidden,
      );

      final ungroupedGroup = Group(
        id: 'ungrouped_group',
        name: 'Ungrouped',
        order: ungroupedGroupOrder,
        isHidden: ungroupedGroupIsHidden,
      );

      List<Group> combinedGroups = [allGroup, ungroupedGroup, ...allDbGroups];

      combinedGroups.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });

      setState(() {
        _groups = combinedGroups;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Prompts the user to add a new group.
  ///
  /// Opens an AlertDialog for the user to enter a new group name.
  /// If a valid name is provided, a new group is created and added to the database.
  Future<void> _addGroup() async {
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
      final newGroup = Group(
        id: const Uuid().v4(),
        name: newGroupName,
        order: _groups.length,
      );
      await _repository.createGroup(newGroup);
      await _loadGroups();
      setState(() {
        _hasChanges = true;
      });
    }
  }

  /// Prompts the user to edit an existing group's name.
  ///
  /// Opens an AlertDialog with the current group name for editing.
  /// If a new valid name is provided, the group is updated in the database.
  Future<void> _editGroup(Group group) async {
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
      final updatedGroup = group.copyWith(name: editedGroupName);
      await _repository.updateGroup(updatedGroup);
      await _loadGroups();
      setState(() {
        _hasChanges = true;
      });
    }
  }

  /// Prompts the user to confirm deletion of a group.
  ///
  /// If confirmed, the group is deleted from the database, and any music pieces
  /// associated *only* with this group are moved to the "Default Group".
  Future<void> _deleteGroup(Group group) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete the group "${group.name}"?\n\nMusic pieces associated ONLY with this group will be moved to the "Default Group".'),
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
      await _repository.deleteGroup(group.id);
      await _loadGroups();
      setState(() {
        _hasChanges = true;
      });
    }
  }

  /// Handles the reordering of groups in the list.
  ///
  /// Updates the order of groups in the local list and persists the new order
  /// to the database or shared preferences for special groups.
  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final Group item = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, item);

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < _groups.length; i++) {
        final group = _groups[i].copyWith(order: i);
        _groups[i] = group;
        if (group.id == 'all_group') {
          await prefs.setInt('all_group_order', group.order);
        } else if (group.id == 'ungrouped_group') {
          await prefs.setInt('ungrouped_group_order', group.order);
        } else {
          await _repository.updateGroup(group);
        }
      }
      setState(() {
        _hasChanges = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving group order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Toggles the visibility of a group.
  ///
  /// Updates the visibility of the group in the local list and persists the
  /// new visibility to the database or shared preferences for special groups.
  Future<void> _toggleGroupVisibility(Group group) async {
    final updatedGroup = group.copyWith(isHidden: !group.isHidden);
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      setState(() {
        _groups[index] = updatedGroup;
        _hasChanges = true;
      });

      final prefs = await SharedPreferences.getInstance();
      if (updatedGroup.id == 'all_group') {
        await prefs.setBool('all_group_isHidden', updatedGroup.isHidden);
      } else if (updatedGroup.id == 'ungrouped_group') {
        await prefs.setBool('ungrouped_group_isHidden', updatedGroup.isHidden);
      } else {
        await _repository.updateGroup(updatedGroup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Groups'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _hasChanges);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ReorderableListView.builder(
                itemCount: _groups.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return ReorderableDragStartListener(
                    index: index,
                    key: ValueKey(group.id),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(group.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(group.isHidden ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => _toggleGroupVisibility(group),
                          ),
                          if (group.id != 'all_group' && group.id != 'ungrouped_group')
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editGroup(group),
                            ),
                          if (group.id != 'all_group' && group.id != 'ungrouped_group')
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteGroup(group),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addGroup,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}