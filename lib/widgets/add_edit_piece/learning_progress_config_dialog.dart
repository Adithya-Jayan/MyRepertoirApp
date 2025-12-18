import 'package:flutter/material.dart';
import '../../models/learning_progress_config.dart';

class LearningProgressConfigDialog extends StatefulWidget {
  final LearningProgressConfig? initialConfig;

  const LearningProgressConfigDialog({super.key, this.initialConfig});

  @override
  State<LearningProgressConfigDialog> createState() => _LearningProgressConfigDialogState();
}

class _LearningProgressConfigDialogState extends State<LearningProgressConfigDialog> {
  late LearningProgressType _type;
  late TextEditingController _maxCountController;
  late List<String> _stages;
  late TextEditingController _stageController;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig ?? LearningProgressConfig(type: LearningProgressType.percentage);
    _type = config.type;
    _maxCountController = TextEditingController(text: config.maxCount.toString());
    _stages = List.from(config.stages);
    _stageController = TextEditingController();
  }

  @override
  void dispose() {
    _maxCountController.dispose();
    _stageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Configure Learning Progress', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<LearningProgressType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: LearningProgressType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            if (_type == LearningProgressType.count) ...[
              TextFormField(
                controller: _maxCountController,
                decoration: const InputDecoration(labelText: 'Max Count'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            if (_type == LearningProgressType.stages) ...[
              const Text('Stages:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: _stages.length,
                  itemBuilder: (context, index) {
                    final stage = _stages[index];
                    return ListTile(
                      key: ValueKey(stage),
                      contentPadding: EdgeInsets.zero,
                      title: GestureDetector(
                        onDoubleTap: () => _renameStage(index),
                        child: Text('${index + 1}. $stage'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _renameStage(index),
                            tooltip: 'Rename',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _stages.removeAt(index);
                              });
                            },
                            tooltip: 'Delete',
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _stages.removeAt(oldIndex);
                      _stages.insert(newIndex, item);
                    });
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stageController,
                      decoration: const InputDecoration(labelText: 'New Stage Name'),
                      onSubmitted: (value) {
                         if (value.isNotEmpty) {
                          if (_stages.contains(value)) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage already exists')));
                             return;
                          }
                          setState(() {
                            _stages.add(value);
                            _stageController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_stageController.text.isNotEmpty) {
                        if (_stages.contains(_stageController.text)) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage already exists')));
                             return;
                        }
                        setState(() {
                          _stages.add(_stageController.text);
                          _stageController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameStage(int index) async {
    final controller = TextEditingController(text: _stages[index]);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Stage'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Rename')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _stages[index]) {
       if (_stages.contains(newName)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage name exists')));
          return;
       }
       setState(() {
         _stages[index] = newName;
       });
    }
  }

  void _save() {
    final newMax = int.tryParse(_maxCountController.text) ?? 10;
    double current = widget.initialConfig?.current ?? 0.0;
    
    // Reset current if type changed
    if (widget.initialConfig?.type != _type) {
       current = 0.0;
    } else {
       // If staying same type, clamp if necessary
       if (_type == LearningProgressType.count) {
          if (current > newMax) current = newMax.toDouble();
       }
       // For stages, if stages removed, clamp index
       if (_type == LearningProgressType.stages) {
          if (current >= _stages.length) current = (_stages.isNotEmpty ? _stages.length - 1 : 0).toDouble();
          if (current < 0) current = 0.0;
       }
    }

    final config = LearningProgressConfig(
      type: _type,
      maxCount: newMax,
      stages: _stages,
      current: current,
    );
    Navigator.of(context).pop(config);
  }
}