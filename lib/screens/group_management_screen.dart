import 'package:flutter/material.dart';
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
    _loadGroups(); // Load the list of groups when the screen initializes.
  }

  /// Loads all groups from the database.
  ///
  /// This method fetches all groups, ensures a default group exists, sorts them,
  /// and updates the UI. It also handles loading states and error reporting.
  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true; // Set loading state to true.
    });
    try {
      await _repository.ensureDefaultGroupExists(); // Ensure the default group is present.
      final allGroups = await _repository.getGroups(); // Fetch all groups.
      allGroups.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order); // Sort by custom order.
        }
        return a.name.compareTo(b.name); // Then sort alphabetically by name.
      });
      setState(() {
        _groups = allGroups.where((g) => !g.isDefault).toList(); // Filter out the default group for display.
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')), // Show error message if loading fails.
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading state to false after operation completes.
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
  /// to the database. It also sets a flag to indicate that changes have been made.
  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final Group item = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, item);

    setState(() {
      _isLoading = true; // Set loading state while reordering is processed.
    });

    try {
      for (int i = 0; i < _groups.length; i++) {
        _groups[i] = _groups[i].copyWith(order: i); // Update the order property of each group.
        await _repository.updateGroup(_groups[i]); // Persist the updated group order to the database.
      }
      setState(() {
        _hasChanges = true; // Set flag to indicate changes were made.
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving group order: $e')), // Show error message if saving fails.
        );
      }
    }
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Reset loading state after operation completes.
        });
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
            : _groups.isEmpty
                ? const Center(
                    child: Text(
                      'No groups yet! Add one to organize your pieces :D',
                      style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ReorderableListView.builder(
                itemCount: _groups.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return Card(
                    key: ValueKey(group.id),
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: ListTile(
                      title: Text(group.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editGroup(group),
                          ),
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