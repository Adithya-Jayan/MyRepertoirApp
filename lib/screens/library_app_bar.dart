import 'package:flutter/material.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/widgets/tag_group_filter_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/screens/settings_screen.dart';
import 'package:repertoire/utils/app_logger.dart';

class LibraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isMultiSelectMode;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool hasActiveFilters;
  final Map<String, dynamic> filterOptions;
  final ValueChanged<Map<String, dynamic>> onFilterOptionsChanged;
  final VoidCallback onApplyFilter;
  final VoidCallback onClearFilter;
  final String sortOption;
  final ValueChanged<String> onSortOptionChanged;
  final VoidCallback onToggleMultiSelectMode;
  final int selectedPieceCount;
  final VoidCallback onSelectAll;
  final MusicPieceRepository repository;
  final SharedPreferences prefs;
  final VoidCallback onSettingsChanged;

  const LibraryAppBar({
    super.key,
    required this.isMultiSelectMode,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.hasActiveFilters,
    required this.filterOptions,
    required this.onFilterOptionsChanged,
    required this.onApplyFilter,
    required this.onClearFilter,
    required this.sortOption,
    required this.onSortOptionChanged,
    required this.onToggleMultiSelectMode,
    required this.selectedPieceCount,
    required this.onSelectAll,
    required this.repository,
    required this.prefs,
    required this.onSettingsChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    AppLogger.log('LibraryAppBar: build called');
    return isMultiSelectMode ? _buildMultiSelectAppBar(context) : _buildDefaultAppBar(context);
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: TextEditingController(text: searchQuery),
        decoration: InputDecoration(
          hintText: 'Search music pieces...',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        onChanged: onSearchChanged,
      ),
      actions: [
        Container(
          decoration: hasActiveFilters
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                )
              : null,
          child: IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter Options'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Title'),
                          initialValue: filterOptions['title'],
                          onChanged: (value) {
                            final newFilterOptions = Map<String, dynamic>.from(filterOptions);
                            newFilterOptions['title'] = value;
                            onFilterOptionsChanged(newFilterOptions);
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final availableTags = await repository.getAllUniqueTagGroups();
                            if (!context.mounted) return;
                            final selectedTags = await showDialog<Map<String, List<String>>>(
                              context: context,
                              builder: (context) => TagGroupFilterDialog(
                                availableTags: availableTags,
                                initialSelectedTags: filterOptions['orderedTags'] ?? {},
                              ),
                            );

                            if (selectedTags != null) {
                              final newFilterOptions = Map<String, dynamic>.from(filterOptions);
                              newFilterOptions['orderedTags'] = selectedTags;
                              onFilterOptionsChanged(newFilterOptions);
                            }
                          },
                          child: const Text('Select Ordered Tags'),
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Practice Tracking'),
                          value: filterOptions['practiceTracking'],
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'enabled', child: Text('Enabled')),
                            DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                          ],
                          onChanged: (value) {
                            final newFilterOptions = Map<String, dynamic>.from(filterOptions);
                            newFilterOptions['practiceTracking'] = value;
                            onFilterOptionsChanged(newFilterOptions);
                          },
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Practice Duration'),
                          value: filterOptions['practiceDuration'],
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Any')),
                            DropdownMenuItem(value: 'last7Days', child: Text('Practiced in last 7 days')),
                            DropdownMenuItem(value: 'notIn30Days', child: Text('Not practiced in 30 days')),
                            DropdownMenuItem(value: 'neverPracticed', child: Text('Never practiced')),
                          ],
                          onChanged: (value) {
                            final newFilterOptions = Map<String, dynamic>.from(filterOptions);
                            newFilterOptions['practiceDuration'] = value;
                            onFilterOptionsChanged(newFilterOptions);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onApplyFilter();
                      },
                      child: const Text('Apply Filter'),
                    ),
                    TextButton(
                      onPressed: () {
                        onClearFilter();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear Filter'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.swap_vert),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sort Options'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Alphabetical'),
                      trailing: sortOption.startsWith('alphabetical') ? (sortOption.endsWith('asc') ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward)) : null,
                      onTap: () {
                        final newSortOption = sortOption == 'alphabetical_asc' ? 'alphabetical_desc' : 'alphabetical_asc';
                        onSortOptionChanged(newSortOption);
                        prefs.setString('sortOption', newSortOption);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text('Last Practiced'),
                      trailing: sortOption.startsWith('last_practiced') ? (sortOption.endsWith('asc') ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward)) : null,
                      onTap: () {
                        final newSortOption = sortOption == 'last_practiced_asc' ? 'last_practiced_desc' : 'last_practiced_asc';
                        onSortOptionChanged(newSortOption);
                        prefs.setString('sortOption', newSortOption);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () async {
            final bool? changesMade = await Navigator.of(context).push<bool?>(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            if (!context.mounted) return;
            if (changesMade == true) {
              onSettingsChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved.')),
              );
            }
          },
        ),
      ],
    );
  }

  AppBar _buildMultiSelectAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onToggleMultiSelectMode,
      ),
      title: Text('$selectedPieceCount selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: onSelectAll,
        ),
      ],
    );
  }
}
