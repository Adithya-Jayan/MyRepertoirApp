import 'package:flutter/material.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/widgets/tag_group_filter_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/screens/settings_screen.dart';
import 'package:repertoire/utils/app_logger.dart';

import 'package:repertoire/l10n/l10n.dart';

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
  final Map<String, Map<String, dynamic>> quickFilters;
  final Function(String, Map<String, dynamic>) onSaveQuickFilter;
  final Function(String) onDeleteQuickFilter;
  final Function(String) onApplyQuickFilter;

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
    required this.quickFilters,
    required this.onSaveQuickFilter,
    required this.onDeleteQuickFilter,
    required this.onApplyQuickFilter,
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
    return widget.isMultiSelectMode
        ? _buildMultiSelectAppBar(context)
        : _buildDefaultAppBar(context);
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.l10n.searchItems,
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.7,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        onChanged: widget.onSearchChanged,
        onSubmitted: widget.onSearchChanged,
      ),
      actions: [
        if (widget.quickFilters.isNotEmpty)
          _QuickFilterButton(
            quickFilters: widget.quickFilters,
            onApply: widget.onApplyQuickFilter,
            onDelete: widget.onDeleteQuickFilter,
            onEdit: widget.onSaveQuickFilter,
            onClear: widget.onClearFilter,
          ),
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
              final theme = Theme.of(context);
              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.tune_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(context.l10n.filterOptions),
                        ],
                      ),
                      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFilterCategoryHeader(
                                theme,
                                context.l10n.textSearch,
                                Icons.search,
                              ),
                              _buildFilterCard(theme, [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: context.l10n.titleContains,
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      prefixIcon: Icon(Icons.title, size: 18),
                                    ),
                                    initialValue: widget.filterOptions['title'],
                                    onChanged: (value) {
                                      final newFilterOptions =
                                          Map<String, dynamic>.from(
                                            widget.filterOptions,
                                          );
                                      newFilterOptions['title'] = value;
                                      widget.onFilterOptionsChanged(
                                        newFilterOptions,
                                      );
                                    },
                                  ),
                                ),
                              ]),

                              const SizedBox(height: 12),
                              _buildFilterCategoryHeader(
                                theme,
                                context.l10n.tags,
                                Icons.label_outline,
                              ),
                              _buildFilterCard(theme, [
                                ListTile(
                                  title: Text(
                                    context.l10n.selectOrderedTags,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  subtitle:
                                      widget.filterOptions['orderedTags'] !=
                                              null &&
                                          (widget.filterOptions['orderedTags']
                                                  as Map)
                                              .isNotEmpty
                                      ? Text(
                                          context.l10n.tagSetsActive(
                                            (widget.filterOptions['orderedTags']
                                                    as Map)
                                                .length,
                                          ),
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 12,
                                          ),
                                        )
                                      : Text(
                                          context.l10n.noTagFiltersActive,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                  ),
                                  onTap: () async {
                                    final availableTags = await widget
                                        .repository
                                        .getAllUniqueTagGroups();
                                    if (!context.mounted) return;
                                    final selectedTags =
                                        await showDialog<
                                          Map<String, List<String>>
                                        >(
                                          context: context,
                                          builder: (context) =>
                                              TagGroupFilterDialog(
                                                availableTags: availableTags,
                                                initialSelectedTags:
                                                    widget
                                                        .filterOptions['orderedTags'] ??
                                                    {},
                                              ),
                                        );

                                    if (selectedTags != null) {
                                      final newFilterOptions =
                                          Map<String, dynamic>.from(
                                            widget.filterOptions,
                                          );
                                      newFilterOptions['orderedTags'] =
                                          selectedTags;
                                      widget.onFilterOptionsChanged(
                                        newFilterOptions,
                                      );
                                      setState(
                                        () {},
                                      ); // Refresh local dialog state
                                    }
                                  },
                                ),
                              ]),

                              const SizedBox(height: 12),
                              _buildFilterCategoryHeader(
                                theme,
                                context.l10n.practiceStatus,
                                Icons.history_edu_outlined,
                              ),
                              _buildFilterCard(theme, [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: context.l10n.tracking,
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                    initialValue: widget
                                        .filterOptions['practiceTracking'],
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(context.l10n.allPieces),
                                      ),
                                      DropdownMenuItem(
                                        value: 'enabled',
                                        child: Text(
                                          context.l10n.trackingEnabled,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'disabled',
                                        child: Text(
                                          context.l10n.trackingDisabled,
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      final newFilterOptions =
                                          Map<String, dynamic>.from(
                                            widget.filterOptions,
                                          );
                                      newFilterOptions['practiceTracking'] =
                                          value;
                                      widget.onFilterOptionsChanged(
                                        newFilterOptions,
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    4,
                                    12,
                                    12,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: context.l10n.lastPracticed,
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                    initialValue: widget
                                        .filterOptions['practiceDuration'],
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(context.l10n.anyTime),
                                      ),
                                      DropdownMenuItem(
                                        value: 'last7Days',
                                        child: Text(
                                          context.l10n.withinLast7Days,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'notIn30Days',
                                        child: Text(
                                          context.l10n.notInLast30Days,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'neverPracticed',
                                        child: Text(
                                          context.l10n.neverPracticed,
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      final newFilterOptions =
                                          Map<String, dynamic>.from(
                                            widget.filterOptions,
                                          );
                                      newFilterOptions['practiceDuration'] =
                                          value;
                                      widget.onFilterOptionsChanged(
                                        newFilterOptions,
                                      );
                                    },
                                  ),
                                ),
                              ]),

                              const SizedBox(height: 16),
                              _buildFilterCard(theme, [
                                ListTile(
                                  leading: const Icon(
                                    Icons.star_border,
                                    size: 20,
                                  ),
                                  title: Text(
                                    context.l10n.saveAsQuickFilter,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  onTap: () async {
                                    final nameController =
                                        TextEditingController();
                                    final name = await showDialog<String>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          context.l10n.saveQuickFilter,
                                        ),
                                        content: TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                            hintText:
                                                context.l10n.enterFilterName,
                                          ),
                                          autofocus: true,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(context.l10n.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              context,
                                              nameController.text,
                                            ),
                                            child: Text(context.l10n.save),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (name != null && name.isNotEmpty) {
                                      widget.onSaveQuickFilter(
                                        name,
                                        widget.filterOptions,
                                      );
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.l10n.filterSaved(name),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            widget.onClearFilter();
                            Navigator.pop(context);
                          },
                          child: Text(context.l10n.clearFilter),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onApplyFilter();
                          },
                          child: Text(context.l10n.applyAndClose),
                        ),
                      ],
                      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    );
                  },
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
                title: Text(context.l10n.sortOptions),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(context.l10n.alphabetical),
                      trailing: widget.sortOption.startsWith('alphabetical')
                          ? (widget.sortOption.endsWith('asc')
                                ? const Icon(Icons.arrow_upward)
                                : const Icon(Icons.arrow_downward))
                          : null,
                      onTap: () {
                        final newSortOption =
                            widget.sortOption == 'alphabetical_asc'
                            ? 'alphabetical_desc'
                            : 'alphabetical_asc';
                        widget.onSortOptionChanged(newSortOption);
                        widget.prefs.setString('sortOption', newSortOption);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: Text(context.l10n.lastPracticed),
                      trailing: widget.sortOption.startsWith('last_practiced')
                          ? (widget.sortOption.endsWith('asc')
                                ? const Icon(Icons.arrow_upward)
                                : const Icon(Icons.arrow_downward))
                          : null,
                      onTap: () {
                        final newSortOption =
                            widget.sortOption == 'last_practiced_asc'
                            ? 'last_practiced_desc'
                            : 'last_practiced_asc';
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
              AppLogger.log(
                'LibraryAppBar: Settings changed, triggering reload',
              );
              // Force a rebuild by triggering a state change
              setState(() {});
              // Call the settings changed callback
              widget.onSettingsChanged();
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
      title: Text(context.l10n.itemsSelected(widget.selectedPieceCount)),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: widget.onSelectAll,
        ),
      ],
    );
  }

  Widget _buildFilterCategoryHeader(
    ThemeData theme,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(ThemeData theme, List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _QuickFilterButton extends StatelessWidget {
  final Map<String, Map<String, dynamic>> quickFilters;
  final Function(String) onApply;
  final Function(String) onDelete;
  final Function(String, Map<String, dynamic>) onEdit;
  final VoidCallback onClear;

  static const String _clearAction = '___CLEAR_FILTERS___';

  const _QuickFilterButton({
    required this.quickFilters,
    required this.onApply,
    required this.onDelete,
    required this.onEdit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.flash_on),
      tooltip: context.l10n.quickFilters,
      onSelected: (value) {
        if (value == _clearAction) {
          onClear();
        } else {
          onApply(value);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: _clearAction,
            child: Row(
              children: [
                Icon(Icons.filter_list_off, size: 20),
                SizedBox(width: 8),
                Text(context.l10n.clearFilter),
              ],
            ),
          ),
          if (quickFilters.isNotEmpty) const PopupMenuDivider(),
          ...quickFilters.keys.map((name) {
            return PopupMenuItem<String>(
              value: name,
              child: Row(
                children: [
                  Expanded(child: Text(name)),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      Navigator.pop(context); // Close menu
                      final action = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(context.l10n.manageFilter(name)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'delete'),
                              child: Text(
                                context.l10n.delete,
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'rename'),
                              child: Text(context.l10n.rename),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(context.l10n.cancel),
                            ),
                          ],
                        ),
                      );

                      if (action == 'delete') {
                        onDelete(name);
                      } else if (action == 'rename') {
                        if (!context.mounted) return;
                        final nameController = TextEditingController(
                          text: name,
                        );
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(context.l10n.renameQuickFilter),
                            content: TextField(
                              controller: nameController,
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(context.l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, nameController.text),
                                child: Text(context.l10n.save),
                              ),
                            ],
                          ),
                        );
                        if (newName != null &&
                            newName.isNotEmpty &&
                            newName != name) {
                          final options = quickFilters[name]!;
                          onDelete(name);
                          onEdit(newName, options);
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          }),
        ];
      },
    );
  }
}
