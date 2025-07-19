import 'package:uuid/uuid.dart';
import '../../models/tag_group.dart';
import '../../database/music_piece_repository.dart';
import '../../utils/app_logger.dart';

class AddEditPieceTagManager {
  final MusicPieceRepository repository;
  final Function(List<TagGroup>) onTagGroupsChanged;

  AddEditPieceTagManager({
    required this.repository,
    required this.onTagGroupsChanged,
  });

  Future<List<String>> loadTagGroupNames() async {
    try {
      final allUniqueTags = await repository.getAllUniqueTagGroups();
      return allUniqueTags.keys.toList()..sort();
    } catch (e) {
      AppLogger.log('Error loading tag group names: $e');
      return [];
    }
  }

  Future<List<String>> getAllTagsForTagGroup(String tagGroupName) async {
    try {
      final allUniqueTags = await repository.getAllUniqueTagGroups();
      return allUniqueTags[tagGroupName]?.toList() ?? [];
    } catch (e) {
      AppLogger.log('Error getting tags for tag group: $e');
      return [];
    }
  }

  void addTagGroup(List<TagGroup> currentTagGroups) {
    final newTagGroups = List<TagGroup>.from(currentTagGroups);
    final newTagGroup = TagGroup(id: const Uuid().v4(), name: '', tags: []);
    newTagGroups.add(newTagGroup);
    onTagGroupsChanged(newTagGroups);
  }

  void updateTagGroup(TagGroup oldTagGroup, TagGroup newTagGroup, List<TagGroup> currentTagGroups) {
    AppLogger.log('AddEditPieceTagManager: Updating tag group "${oldTagGroup.name}" color from ${oldTagGroup.color} to ${newTagGroup.color}');
    final updatedTagGroups = List<TagGroup>.from(currentTagGroups);
    final index = updatedTagGroups.indexWhere((element) => element.id == oldTagGroup.id);
    if (index != -1) {
      updatedTagGroups[index] = newTagGroup;
      onTagGroupsChanged(updatedTagGroups);
    }
  }

  void deleteTagGroup(TagGroup tagGroup, List<TagGroup> currentTagGroups) {
    final updatedTagGroups = List<TagGroup>.from(currentTagGroups);
    updatedTagGroups.remove(tagGroup);
    onTagGroupsChanged(updatedTagGroups);
  }

  void reorderTagGroups(int oldIndex, int newIndex, List<TagGroup> currentTagGroups) {
    final updatedTagGroups = List<TagGroup>.from(currentTagGroups);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final tagGroup = updatedTagGroups.removeAt(oldIndex);
    updatedTagGroups.insert(newIndex, tagGroup);
    onTagGroupsChanged(updatedTagGroups);
  }
} 