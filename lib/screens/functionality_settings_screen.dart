import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/services/update_service.dart';
import 'package:repertoire/models/practice_stage.dart';
import 'package:repertoire/services/practice_config_service.dart';
import 'package:repertoire/utils/theme_notifier.dart';
import 'package:repertoire/utils/permissions_utils.dart';
import 'package:uuid/uuid.dart';

import 'package:repertoire/l10n/l10n.dart';

class FunctionalitySettingsScreen extends StatefulWidget {
  const FunctionalitySettingsScreen({super.key});

  @override
  State<FunctionalitySettingsScreen> createState() =>
      _FunctionalitySettingsScreenState();
}

class _FunctionalitySettingsScreenState
    extends State<FunctionalitySettingsScreen> {
  final PracticeConfigService _configService = PracticeConfigService();
  List<PracticeStage> _stages = [];
  bool _isLoading = true;

  bool _showPracticeTimeStats = false;
  bool _showPracticeNotes = false;
  bool _notifyNewReleases = false;
  bool _isPlayStore = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final stages = await _configService.loadStages();
    final isPlayStore = await isPlayStoreBuild();

    if (!mounted) return;
    setState(() {
      _stages = stages;
      _showPracticeTimeStats =
          prefs.getBool('show_practice_time_stats') ?? false;
      _showPracticeNotes = prefs.getBool('show_practice_notes') ?? false;
      _notifyNewReleases = prefs.getBool('notifyNewReleases') ?? true;
      _isPlayStore = isPlayStore;
      _isLoading = false;
    });
  }

  Future<void> _saveStages() async {
    await _configService.saveStages(_stages);
  }

  Future<void> _saveOtherSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_practice_time_stats', _showPracticeTimeStats);
    await prefs.setBool('show_practice_notes', _showPracticeNotes);
    await prefs.setBool('notifyNewReleases', _notifyNewReleases);
  }

  void _addStage() {
    if (_stages.length >= 10) return;
    setState(() {
      _stages.add(
        PracticeStage(
          id: const Uuid().v4(),
          name: context.l10n.stageDefaultName(_stages.length + 1),
          colorValue: Colors.grey.toARGB32(),
          holdDays: 0,
          transitionDays: 7,
        ),
      );
    });
    _saveStages();
  }

  void _removeStage(int index) {
    setState(() {
      _stages.removeAt(index);
    });
    _saveStages();
  }

  void _updateStage(int index, PracticeStage newStage) {
    setState(() {
      _stages[index] = newStage;
    });
    _saveStages();
  }

  Future<void> _pickColor(int index) async {
    final stage = _stages[index];
    final Color? newColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.selectColor),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      ...ThemeNotifier.availableAccentColors,
                      Colors.black,
                      Colors.grey,
                      Colors.blueGrey,
                      Colors.brown,
                      Colors.cyan,
                      Colors.lime,
                      Colors.amber,
                      Colors.deepOrange,
                    ]
                    .map(
                      (color) => GestureDetector(
                        onTap: () => Navigator.pop(context, color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stage.colorValue == color.toARGB32()
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );

    if (newColor != null) {
      _updateStage(
        index,
        PracticeStage(
          id: stage.id,
          name: stage.name,
          colorValue: newColor.toARGB32(),
          holdDays: stage.holdDays,
          transitionDays: stage.transitionDays,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.functionality),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            children: [
              _buildCategoryHeader(
                theme,
                context.l10n.practiceTracking,
                Icons.timeline_outlined,
              ),
              _buildSettingsCard([
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.trackingStages,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context
                            .l10n
                            .stagesForPracticeIndicatorsDragToReorderDoubleTapNameToEdit,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Header Row for stages
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      SizedBox(width: 24),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          context.l10n.status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        context.l10n.color,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Text(
                          context.l10n.hold,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Text(
                          context.l10n.trans,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 32),
                    ],
                  ),
                ),
                const Divider(indent: 12, endIndent: 12),

                ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _stages.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _stages.removeAt(oldIndex);
                      _stages.insert(newIndex, item);
                    });
                    _saveStages();
                  },
                  itemBuilder: (context, index) {
                    final stage = _stages[index];
                    final isLast = index == _stages.length - 1;

                    return Padding(
                      key: ValueKey(stage.id),
                      padding: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 8.0,
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),

                          Expanded(
                            flex: 3,
                            child: _EditableLabel(
                              value: stage.name,
                              onChanged: (val) {
                                setState(() {
                                  _stages[index].name = val;
                                });
                                _saveStages();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          GestureDetector(
                            onTap: () => _pickColor(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(stage.colorValue),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            flex: 1,
                            child: isLast
                                ? const Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : TextFormField(
                                    initialValue: stage.holdDays.toString(),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final days = int.tryParse(val) ?? 0;
                                      _stages[index].holdDays = days;
                                      _saveStages();
                                    },
                                  ),
                          ),
                          const SizedBox(width: 8),

                          Expanded(
                            flex: 1,
                            child: isLast
                                ? const Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : TextFormField(
                                    initialValue: stage.transitionDays
                                        .toString(),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final days = int.tryParse(val) ?? 0;
                                      _stages[index].transitionDays = days;
                                      _saveStages();
                                    },
                                  ),
                          ),

                          if (_stages.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _removeStage(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            )
                          else
                            const SizedBox(width: 24),
                        ],
                      ),
                    );
                  },
                ),

                if (_stages.length < 10)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        context.l10n.addStage,
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: _addStage,
                    ),
                  ),
              ]),

              const SizedBox(height: 16),
              _buildCategoryHeader(
                theme,
                context.l10n.practiceOptions,
                Icons.auto_graph_outlined,
              ),
              _buildSettingsCard([
                SwitchListTile(
                  title: Text(context.l10n.practiceTimeStats),
                  subtitle: Text(context.l10n.showDurationAndStatsInLogs),
                  value: _showPracticeTimeStats,
                  onChanged: (v) {
                    setState(() => _showPracticeTimeStats = v);
                    _saveOtherSettings();
                  },
                ),
                SwitchListTile(
                  title: Text(context.l10n.practiceNotes),
                  subtitle: Text(context.l10n.allowAddingNotesToSessions),
                  value: _showPracticeNotes,
                  onChanged: (v) {
                    setState(() => _showPracticeNotes = v);
                    _saveOtherSettings();
                  },
                ),
              ]),

              if (!_isPlayStore) ...[
                const SizedBox(height: 16),
                _buildCategoryHeader(
                  theme,
                  context.l10n.updates,
                  Icons.system_update_outlined,
                ),
                _buildSettingsCard([
                  SwitchListTile(
                    title: Text(context.l10n.notifyNewReleases),
                    subtitle: Text(context.l10n.checkGithubForAppUpdates),
                    value: _notifyNewReleases,
                    onChanged: (v) {
                      setState(() => _notifyNewReleases = v);
                      _saveOtherSettings();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(context.l10n.checkForUpdatesNow),
                        onPressed: () => UpdateService().checkForUpdates(
                          context,
                          manual: true,
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _EditableLabel extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _EditableLabel({required this.value, required this.onChanged});

  @override
  State<_EditableLabel> createState() => _EditableLabelState();
}

class _EditableLabelState extends State<_EditableLabel> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _isEditing = false;
        });
        if (_controller.text != widget.value) {
          widget.onChanged(_controller.text);
        }
      }
    });
  }

  @override
  void didUpdateWidget(_EditableLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !_isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        ),
        style: const TextStyle(fontSize: 13),
        onFieldSubmitted: (val) {
          setState(() {
            _isEditing = false;
          });
          widget.onChanged(val);
        },
      );
    }
    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _isEditing = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent, // Hit test
        child: Text(
          widget.value,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
