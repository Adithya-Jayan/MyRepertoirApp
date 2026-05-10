import 'package:flutter/material.dart';
import 'package:repertoire/models/pdf_config.dart';

class PdfConfigDialog extends StatefulWidget {
  final PdfConfig initialConfig;

  const PdfConfigDialog({super.key, required this.initialConfig});

  @override
  State<PdfConfigDialog> createState() => _PdfConfigDialogState();
}

class _PdfConfigDialogState extends State<PdfConfigDialog> {
  late bool _autoScrollEnabled;
  late double _defaultSpeed;

  @override
  void initState() {
    super.initState();
    _autoScrollEnabled = widget.initialConfig.autoScrollEnabled;
    _defaultSpeed = widget.initialConfig.defaultSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure PDF Viewer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Auto Scroll Enabled'),
            subtitle: const Text('Show scroll controls in the viewer'),
            value: _autoScrollEnabled,
            onChanged: (value) {
              setState(() {
                _autoScrollEnabled = value;
              });
            },
          ),
          if (_autoScrollEnabled) ...[
            const SizedBox(height: 16),
            const Text('Initial Speed'),
            Slider(
              min: 0.1,
              max: 5.0,
              divisions: 49,
              value: _defaultSpeed,
              onChanged: (value) {
                setState(() {
                  _defaultSpeed = value;
                });
              },
            ),
            Text('${_defaultSpeed.toStringAsFixed(1)}x'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              PdfConfig(
                autoScrollEnabled: _autoScrollEnabled,
                defaultSpeed: _defaultSpeed,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
