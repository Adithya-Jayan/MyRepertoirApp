import 'package:flutter/material.dart';
import 'package:repertoire/models/pdf_config.dart';

import 'package:repertoire/l10n/l10n.dart';

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
      title: Text(context.l10n.configurePdfViewer),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: Text(context.l10n.autoScrollEnabled),
            subtitle: Text(context.l10n.showScrollControlsInTheViewer),
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
          child: Text(context.l10n.cancel),
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
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}
