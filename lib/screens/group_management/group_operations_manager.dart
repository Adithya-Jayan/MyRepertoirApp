import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/group.dart';
import '../../database/music_piece_repository.dart';
import '../../utils/app_logger.dart';

class GroupOperationsManager {
  final MusicPieceRepository repository;

  GroupOperationsManager({required this.repository});

  /// Loads all groups from the database and shared preferences.
  ///
  /// This method fetches all user-created groups from the database and
  /// loads the settings for the special "All" and "Ungrouped" groups from
  /// shared preferences. It then combines and sorts them for display.
  Future<List<Group>> loadGroups() async {
    AppLogger.log('GroupOperationsManager: loadGroups called');
    try {
      final prefs = await SharedPreferences.getInstance();
      final allDbGroups = await repository.getGroups();
      AppLogger.log('GroupOperationsManager: Loaded ${allDbGroups.length} groups from DB.');

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

      AppLogger.log('GroupOperationsManager: Combined and sorted groups: ${combinedGroups.map((g) => '${g.name} (id: ${g.id}, order: ${g.order}, hidden: ${g.isHidden})').join(', ')}');
      return combinedGroups;
    } catch (e) {
      AppLogger.log('GroupOperationsManager: Error loading groups: $e');
      rethrow;
    }
  }

  /// Handles the reordering of groups in the list.
  ///
  /// Updates the order of groups in the local list and persists the new order
  /// to the database or shared preferences for special groups.
  Future<void> saveGroupOrder(List<Group> groups) async {
    AppLogger.log('GroupOperationsManager: saveGroupOrder called');
    try {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < groups.length; i++) {
        final group = groups[i].copyWith(order: i);
        if (group.id == 'all_group') {
          await prefs.setInt('all_group_order', group.order);
          AppLogger.log('GroupOperationsManager: Saved All group order: ${group.order}');
        } else if (group.id == 'ungrouped_group') {
          await prefs.setInt('ungrouped_group_order', group.order);
          AppLogger.log('GroupOperationsManager: Saved Ungrouped group order: ${group.order}');
        } else {
          await repository.updateGroup(group);
          AppLogger.log('GroupOperationsManager: Saved group ${group.name} order: ${group.order}');
        }
      }
    } catch (e) {
      AppLogger.log('GroupOperationsManager: Error saving group order: $e');
      rethrow;
    }
  }

  /// Toggles the visibility of a group.
  ///
  /// Updates the visibility of the group in the local list and persists the
  /// new visibility to the database or shared preferences for special groups.
  Future<Group> toggleGroupVisibility(Group group) async {
    final updatedGroup = group.copyWith(isHidden: !group.isHidden);
    
    final prefs = await SharedPreferences.getInstance();
    if (updatedGroup.id == 'all_group') {
      await prefs.setBool('all_group_isHidden', updatedGroup.isHidden);
      AppLogger.log('GroupOperationsManager: Toggled visibility for All group to: ${updatedGroup.isHidden}');
    } else if (updatedGroup.id == 'ungrouped_group') {
      await prefs.setBool('ungrouped_group_isHidden', updatedGroup.isHidden);
      AppLogger.log('GroupOperationsManager: Toggled visibility for Ungrouped group to: ${updatedGroup.isHidden}');
    } else {
      await repository.updateGroup(updatedGroup);
      AppLogger.log('GroupOperationsManager: Toggled visibility for group ${updatedGroup.name} to: ${updatedGroup.isHidden}');
    }
    
    return updatedGroup;
  }

  /// Creates a new group and adds it to the database.
  Future<Group> createGroup(String name, int order) async {
    final newGroup = Group(
      id: const Uuid().v4(),
      name: name,
      order: order,
    );
    AppLogger.log('GroupOperationsManager: Creating new group: ${newGroup.name} (id: ${newGroup.id})');
    await repository.createGroup(newGroup);
    return newGroup;
  }

  /// Updates an existing group in the database.
  Future<void> updateGroup(Group group) async {
    AppLogger.log('GroupOperationsManager: Updating group: ${group.name} (id: ${group.id})');
    await repository.updateGroup(group);
  }

  /// Deletes a group from the database.
  Future<void> deleteGroup(String groupId) async {
    AppLogger.log('GroupOperationsManager: Deleting group with id: $groupId');
    await repository.deleteGroup(groupId);
  }
} 