import 'package:flutter/material.dart';
import 'package:repertoire/models/group.dart';
import '../utils/app_logger.dart';

class LibraryUtils {
  /// Returns a list of groups that should be visible in the UI.
  ///
  /// If there are no user-created groups, this method returns an empty list.
  /// Otherwise, it returns all groups that are not hidden.
  static List<Group> getVisibleGroups(List<Group> groups) {
    final userGroups = groups.where((g) => g.id != 'all_group' && g.id != 'ungrouped_group').toList();
    List<Group> visibleGroups;
    if (userGroups.isEmpty) {
      visibleGroups = groups.where((g) => !g.isHidden && (g.id == 'all_group' || g.id == 'ungrouped_group')).toList();
    } else {
      visibleGroups = groups.where((g) => !g.isHidden).toList();
    }
    AppLogger.log('LibraryScreen: Visible groups: ${visibleGroups.map((g) => '${g.name} (id: ${g.id}, hidden: ${g.isHidden})').join(', ')}');
    return visibleGroups;
  }

  /// Calculates the scroll offset for a given group chip index.
  ///
  /// This is used to programmatically scroll the horizontal list of group chips
  /// into view when a different group page is selected in the PageView.
  static double calculateScrollOffset(int index, ScrollController groupScrollController) {
    // This is a simplified calculation. For precise calculation, you'd need to measure widget sizes.
    // A more robust solution would involve using GlobalKey to get the render box of each chip.
    const double chipWidth = 100.0; // Approximate width of a chip.
    const double paddingAndSpacing = 8.0; // Combined horizontal padding and spacing between chips.
    double offset = (index * (chipWidth + paddingAndSpacing));

    // Ensure the calculated offset does not exceed the maximum scroll extent
    // of the SingleChildScrollView, preventing over-scrolling.
    if (groupScrollController.hasClients) {
      return offset.clamp(0.0, groupScrollController.position.maxScrollExtent);
    }
    return offset;
  }
}
