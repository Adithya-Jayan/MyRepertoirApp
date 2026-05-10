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

  @override
  void initState() {
    super.initState();
    _autoScrollEnabled = widget.initialConfig.autoScrollEnabled;
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
                defaultSpeed: 1.0, // Default to 1.0
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
