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
  late Map<int, String?> _channelNames;
  List<int> _activeChannels = [];
  bool _isLoading = true;
  int? _editingChannel;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _channelNames = {};
    _initData();
  }

  Future<void> _initData() async {
    final active = await MidiUtils.getActiveChannels(widget.midiPath);
    final fileNames = await MidiUtils.getChannelNames(widget.midiPath);

    if (mounted) {
      setState(() {
        _activeChannels = active;
        for (var ch in _activeChannels) {
          // Priority: 1. Existing custom name from initialConfig, 2. Name from MIDI file, 3. null
          final existingConfig = widget.initialConfig.channels[ch];
          final customName = existingConfig?.name;
          
          if (customName != null && customName.trim().isNotEmpty) {
            _channelNames[ch] = customName.trim();
          } else {
            _channelNames[ch] = fileNames[ch];
          }
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing(int ch) {
    setState(() {
      _editingChannel = ch;
      _editController.text = _channelNames[ch] ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
        _editController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _editController.text.length,
        );
      }
    });
  }

  void _saveEdit() {
    if (_editingChannel != null) {
      setState(() {
        final newName = _editController.text.trim();
        _channelNames[_editingChannel!] = newName.isNotEmpty ? newName : null;
        _editingChannel = null;
      });
    }
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
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '(Double tap name to edit)',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _activeChannels.length,
                      itemBuilder: (context, index) {
                        final ch = _activeChannels[index];
                        final name = _channelNames[ch];
                        final bool isEditing = _editingChannel == ch;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: InkWell( // Use InkWell for better touch feedback
                            onDoubleTap: () => _startEditing(ch),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    'Ch ${ch + 1} : ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  child: isEditing
                                      ? TextField(
                                          controller: _editController,
                                          focusNode: _focusNode,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                          onSubmitted: (_) => _saveEdit(),
                                          onEditingComplete: () => _saveEdit(),
                                          autofocus: true,
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            (name != null && name.isNotEmpty) ? name : 'Blank',
                                            style: TextStyle(
                                              color: (name != null && name.isNotEmpty) ? null : Colors.grey,
                                              fontStyle: (name != null && name.isNotEmpty) ? null : FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Save current edit if any
            if (_editingChannel != null) _saveEdit();

            final Map<int, ChannelConfig> updatedChannels = Map.from(widget.initialConfig.channels);
            _channelNames.forEach((ch, name) {
              final existing = updatedChannels[ch] ?? ChannelConfig();
              // Explicitly set the name to allow clearing (setting to null)
              updatedChannels[ch] = ChannelConfig(
                name: name,
                volume: existing.volume,
                mute: existing.mute,
              );
            });
            Navigator.pop(context, widget.initialConfig.copyWith(channels: updatedChannels));
          },
          child: const Text('Save All'),
        ),
      ],
    );
  }
}
