import 'package:flutter/material.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/widgets/tag_group_filter_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/screens/settings_screen.dart';
import 'package:repertoire/utils/app_logger.dart';

class LibraryAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<LibraryAppBar> createState() => _LibraryAppBarState();
}

class _LibraryAppBarState extends State<LibraryAppBar> {
  late TextEditingController _searchController;


  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(LibraryAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('LibraryAppBar: build called');
    return widget.isMultiSelectMode ? _buildMultiSelectAppBar(context) : _buildDefaultAppBar(context);
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search items...',
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
        onChanged: widget.onSearchChanged,
        onSubmitted: widget.onSearchChanged,
      ),
      actions: [
        Container(
          decoration: widget.hasActiveFilters
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
                          initialValue: widget.filterOptions['title'],
                          onChanged: (value) {
                            final newFilterOptions = Map<String, dynamic>.from(widget.filterOptions);
                            newFilterOptions['title'] = value;
                            widget.onFilterOptionsChanged(newFilterOptions);
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final availableTags = await widget.repository.getAllUniqueTagGroups();
                            if (!context.mounted) return;
                            final selectedTags = await showDialog<Map<String, List<String>>>(
                              context: context,
                              builder: (context) => TagGroupFilterDialog(
                                availableTags: availableTags,
                                initialSelectedTags: widget.filterOptions['orderedTags'] ?? {},
                              ),
                            );

                            if (selectedTags != null) {
                              final newFilterOptions = Map<String, dynamic>.from(widget.filterOptions);
                              newFilterOptions['orderedTags'] = selectedTags;
                              widget.onFilterOptionsChanged(newFilterOptions);
                            }
                          },
                          child: const Text('Select Ordered Tags'),
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Practice Tracking'),
                          initialValue: widget.filterOptions['practiceTracking'],
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'enabled', child: Text('Enabled')),
                            DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                          ],
                          onChanged: (value) {
                            final newFilterOptions = Map<String, dynamic>.from(widget.filterOptions);
                            newFilterOptions['practiceTracking'] = value;
                            widget.onFilterOptionsChanged(newFilterOptions);
                          },
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Practice Duration'),
                          initialValue: widget.filterOptions['practiceDuration'],
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Any')),
                            DropdownMenuItem(value: 'last7Days', child: Text('Practiced in last 7 days')),
                            DropdownMenuItem(value: 'notIn30Days', child: Text('Not practiced in 30 days')),
                            DropdownMenuItem(value: 'neverPracticed', child: Text('Never practiced')),
                          ],
                          onChanged: (value) {
                            final newFilterOptions = Map<String, dynamic>.from(widget.filterOptions);
                            newFilterOptions['practiceDuration'] = value;
                            widget.onFilterOptionsChanged(newFilterOptions);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        widget.onClearFilter();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear Filter'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onApplyFilter();
                      },
                      child: const Text('Apply Filter'),
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
                      trailing: widget.sortOption.startsWith('alphabetical') ? (widget.sortOption.endsWith('asc') ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward)) : null,
                      onTap: () {
                        final newSortOption = widget.sortOption == 'alphabetical_asc' ? 'alphabetical_desc' : 'alphabetical_asc';
                        widget.onSortOptionChanged(newSortOption);
                        widget.prefs.setString('sortOption', newSortOption);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text('Last Practiced'),
                      trailing: widget.sortOption.startsWith('last_practiced') ? (widget.sortOption.endsWith('asc') ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward)) : null,
                      onTap: () {
                        final newSortOption = widget.sortOption == 'last_practiced_asc' ? 'last_practiced_desc' : 'last_practiced_asc';
                        widget.onSortOptionChanged(newSortOption);
                        widget.prefs.setString('sortOption', newSortOption);
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
              // Trigger reload when returning from settings with changes
              AppLogger.log('LibraryAppBar: Settings changed, triggering reload');
              // Force a rebuild by triggering a state change
              setState(() {});
              // Call the settings changed callback
              widget.onSettingsChanged();
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
        onPressed: widget.onToggleMultiSelectMode,
      ),
      title: Text('${widget.selectedPieceCount} selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: widget.onSelectAll,
        ),
      ],
    );
  }
}
