import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/services/update_service.dart';
import 'package:repertoire/models/practice_stage.dart';
import 'package:repertoire/services/practice_config_service.dart';
import 'package:repertoire/utils/theme_notifier.dart';
import 'package:uuid/uuid.dart';

class FunctionalitySettingsScreen extends StatefulWidget {
  const FunctionalitySettingsScreen({super.key});

  @override
  State<FunctionalitySettingsScreen> createState() =>
      _FunctionalitySettingsScreenState();
}

class _FunctionalitySettingsScreenState extends State<FunctionalitySettingsScreen> {
  final PracticeConfigService _configService = PracticeConfigService();
  List<PracticeStage> _stages = [];
  bool _isLoading = true;
  
  bool _showPracticeTimeStats = false;
  bool _notifyNewReleases = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final stages = await _configService.loadStages();
    
    if (!mounted) return;
    setState(() {
      _stages = stages;
      _showPracticeTimeStats = prefs.getBool('show_practice_time_stats') ?? false;
      _notifyNewReleases = prefs.getBool('notifyNewReleases') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveStages() async {
    await _configService.saveStages(_stages);
  }
  
  Future<void> _saveOtherSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_practice_time_stats', _showPracticeTimeStats);
    await prefs.setBool('notifyNewReleases', _notifyNewReleases);
  }

  void _addStage() {
    if (_stages.length >= 10) return;
    setState(() {
      _stages.add(PracticeStage(
        id: const Uuid().v4(),
        name: 'New Stage',
        colorValue: Colors.grey.toARGB32(),
        holdDays: 0,
        transitionDays: 7,
      ));
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
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...ThemeNotifier.availableAccentColors,
              Colors.black,
              Colors.grey,
              Colors.blueGrey,
              Colors.brown,
              Colors.cyan,
              Colors.lime,
              Colors.amber,
              Colors.deepOrange,
            ].map((color) => GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stage.colorValue == color.toARGB32() ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );

    if (newColor != null) {
      _updateStage(index, PracticeStage(
        id: stage.id,
        name: stage.name,
        colorValue: newColor.toARGB32(),
        holdDays: stage.holdDays,
        transitionDays: stage.transitionDays,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Functionality'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Tracking Stages',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                   'Configure the stages of practice indicators. Drag to reorder. Double tap name to edit.',
                   style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Header Row
                const Row(
                   children: [
                      SizedBox(width: 32), // Placeholder for drag handle
                      SizedBox(width: 8),
                      Expanded(flex: 3, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 8),
                      Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 16),
                      Expanded(flex: 1, child: Text('Hold', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 8),
                      Expanded(flex: 1, child: Text('Trans', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 40),
                   ],
                ),
                const Divider(),

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
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),

                          // Status Name (Editable Label)
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
                          
                          // Color Picker
                          GestureDetector(
                            onTap: () => _pickColor(index),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(stage.colorValue),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Hold Days
                          Expanded(
                            flex: 1,
                            child: isLast
                              ? const Center(child: Text('-'))
                              : TextFormField(
                                  initialValue: stage.holdDays.toString(),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                                  onChanged: (val) {
                                    final days = int.tryParse(val) ?? 0;
                                    _stages[index].holdDays = days;
                                    _saveStages();
                                  },
                                ),
                          ),
                          const SizedBox(width: 8),

                          // Transition Days
                          Expanded(
                            flex: 1,
                            child: isLast 
                              ? const Center(child: Text('-'))
                              : TextFormField(
                                  initialValue: stage.transitionDays.toString(),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                                  onChanged: (val) {
                                    final days = int.tryParse(val) ?? 0;
                                    _stages[index].transitionDays = days;
                                    _saveStages();
                                  },
                                ),
                          ),
                          
                          // Remove Button
                          if (_stages.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _removeStage(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Stage'),
                        onPressed: _addStage,
                    ),
                  ),

                const SizedBox(height: 24),
                const Divider(),
                SwitchListTile(
                  title: const Text('Show Practice Time Statistics'),
                  subtitle: const Text('Display duration and time-based statistics in practice logs'),
                  value: _showPracticeTimeStats,
                  onChanged: (bool value) {
                    setState(() {
                      _showPracticeTimeStats = value;
                    });
                    _saveOtherSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text('Notify New Releases'),
                  subtitle: const Text('Show a popup when a new version is available on GitHub.'),
                  value: _notifyNewReleases,
                  onChanged: (bool value) {
                    setState(() {
                      _notifyNewReleases = value;
                    });
                    _saveOtherSettings();
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Check for Updates Now'),
                    onPressed: () {
                      UpdateService().checkForUpdates(context, manual: true);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8)),
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