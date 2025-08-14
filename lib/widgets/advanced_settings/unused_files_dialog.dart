import 'package:flutter/material.dart';

/// A dialog that displays a list of unused files.
class UnusedFilesDialog extends StatelessWidget {
  final List<String> unusedFiles;

  const UnusedFilesDialog({
    super.key,
    required this.unusedFiles,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unused Files'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: unusedFiles.length,
          itemBuilder: (context, index) {
            return Text(unusedFiles[index]);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
