import 'package:flutter/material.dart';
import '../../models/midi_track_config.dart';
import '../../utils/midi_utils.dart';

class MidiTrackConfigDialog extends StatefulWidget {
  final String midiPath;
  final MidiTrackConfig initialConfig;

  const MidiTrackConfigDialog({
    super.key,
    required this.midiPath,
    required this.initialConfig,
  });

  @override
  State<MidiTrackConfigDialog> createState() => _MidiTrackConfigDialogState();
}

class _MidiTrackConfigDialogState extends State<MidiTrackConfigDialog> {
  late Map<int, TextEditingController> _controllers;
  List<int> _activeChannels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _initData();
  }

  Future<void> _initData() async {
    final active = await MidiUtils.getActiveChannels(widget.midiPath);
    final names = await MidiUtils.getChannelNames(widget.midiPath);

    if (mounted) {
      setState(() {
        _activeChannels = active;
        for (var ch in _activeChannels) {
          final existingName = widget.initialConfig.channels[ch]?.name ?? names[ch] ?? '';
          _controllers[ch] = TextEditingController(text: existingName);
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('MIDI Channel Names'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _activeChannels.map((ch) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextField(
                      controller: _controllers[ch],
                      decoration: InputDecoration(
                        labelText: 'Channel ${ch + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final Map<int, ChannelConfig> updatedChannels = Map.from(widget.initialConfig.channels);
            _controllers.forEach((ch, controller) {
              final existing = updatedChannels[ch] ?? ChannelConfig();
              updatedChannels[ch] = existing.copyWith(name: controller.text);
            });
            Navigator.pop(context, widget.initialConfig.copyWith(channels: updatedChannels));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
