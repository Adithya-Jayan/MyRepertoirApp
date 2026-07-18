import 'package:flutter/material.dart';
import '../../models/learning_progress_config.dart';

import 'package:repertoire/l10n/l10n.dart';

class LearningProgressConfigDialog extends StatefulWidget {
  final LearningProgressConfig? initialConfig;

  const LearningProgressConfigDialog({super.key, this.initialConfig});

  @override
  State<LearningProgressConfigDialog> createState() =>
      _LearningProgressConfigDialogState();
}

class _LearningProgressConfigDialogState
    extends State<LearningProgressConfigDialog> {
  late LearningProgressType _type;
  late TextEditingController _maxCountController;
  late List<String> _stages;
  late TextEditingController _stageController;

  @override
  void initState() {
    super.initState();
    final config =
        widget.initialConfig ??
        LearningProgressConfig(type: LearningProgressType.percentage);
    _type = config.type;
    _maxCountController = TextEditingController(
      text: config.maxCount.toString(),
    );
    _stages = List.from(config.stages);
    _stageController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stages.isEmpty && _type == LearningProgressType.stages) {
      _stages.add(context.l10n.stageDefaultName(1));
    }
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
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 24.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.configureLearningProgress,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LearningProgressType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: context.l10n.type),
              items: LearningProgressType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.localizedName(context.l10n)),
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
                decoration: InputDecoration(labelText: context.l10n.maxCount),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            if (_type == LearningProgressType.stages) ...[
              Text(
                context.l10n.stages,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                        child: Text(
                          context.l10n.numberedStage(index + 1, stage),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _renameStage(index),
                            tooltip: context.l10n.rename,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _stages.removeAt(index);
                              });
                            },
                            tooltip: context.l10n.delete,
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
                      decoration: InputDecoration(
                        labelText: context.l10n.newStageName,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          if (_stages.contains(value)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.stageAlreadyExists),
                              ),
                            );
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.stageAlreadyExists),
                            ),
                          );
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
                  child: Text(context.l10n.cancel),
                ),
                TextButton(onPressed: _save, child: Text(context.l10n.save)),
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
        title: Text(context.l10n.renameStage),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.rename),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _stages[index]) {
      if (_stages.contains(newName)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.stageNameExists)));
        }
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
        if (current >= _stages.length) {
          current = (_stages.isNotEmpty ? _stages.length - 1 : 0).toDouble();
        }
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
