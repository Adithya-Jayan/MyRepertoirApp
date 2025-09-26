import 'package:flutter/material.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/group.dart';
import '../utils/app_logger.dart';
import 'group_management/group_dialog_manager.dart';
import 'group_management/group_operations_manager.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final MusicPieceRepository _repository = MusicPieceRepository();
  late final GroupOperationsManager _operationsManager;
  List<Group> _groups = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _operationsManager = GroupOperationsManager(repository: _repository);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    AppLogger.log('GroupManagementScreen: _loadGroups called');
    setState(() {
      _isLoading = true;
    });
    try {
      final groups = await _operationsManager.loadGroups();
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      AppLogger.log('GroupManagementScreen: Error loading groups: $e');
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

  Future<void> _addGroup() async {
    final newGroupName = await GroupDialogManager.showAddGroupDialog(context);
    if (newGroupName != null) {
      try {
        await _operationsManager.createGroup(newGroupName, _groups.length);
        await _loadGroups();
        setState(() {
          _hasChanges = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding group: $e')),
          );
        }
      }
    }
  }

  Future<void> _editGroup(Group group) async {
    final editedGroupName = await GroupDialogManager.showEditGroupDialog(context, group);
    if (editedGroupName != null) {
      try {
        final updatedGroup = group.copyWith(name: editedGroupName);
        await _operationsManager.updateGroup(updatedGroup);
        await _loadGroups();
        setState(() {
          _hasChanges = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating group: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final confirmDelete = await GroupDialogManager.showDeleteGroupDialog(context, group);
    if (confirmDelete) {
      try {
        await _operationsManager.deleteGroup(group.id);
        await _loadGroups();
        setState(() {
          _hasChanges = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting group: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveGroupOrder() async {
    AppLogger.log('GroupManagementScreen: _saveGroupOrder called');
    try {
      await _operationsManager.saveGroupOrder(_groups);
      setState(() {
        _hasChanges = true;
      });
    } catch (e) {
      AppLogger.log('GroupManagementScreen: Error saving group order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving group order: $e')),
        );
      }
    }
  }

  Future<void> _toggleGroupVisibility(Group group) async {
    try {
      final updatedGroup = await _operationsManager.toggleGroupVisibility(group);
      final index = _groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        setState(() {
          _groups[index] = updatedGroup;
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling group visibility: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    AppLogger.log('GroupManagementScreen: dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _saveGroupOrder();
        }
      },
      child: SafeArea(
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
            : _buildGroupList(),
        floatingActionButton: FloatingActionButton(
          onPressed: _addGroup,
          child: const Icon(Icons.add),
        ),
      ),
    ),
    );
  }

  Widget _buildGroupList() {
    return ReorderableListView.builder(
      itemCount: _groups.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final Group item = _groups.removeAt(oldIndex);
          _groups.insert(newIndex, item);
          _saveGroupOrder();
        });
      },
      itemBuilder: (context, index) {
        final group = _groups[index];
        return ReorderableDragStartListener(
          index: index,
          key: ValueKey(group.id),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.drag_handle, color: Colors.grey),
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
          ),
        );
      },
    );
  }
}