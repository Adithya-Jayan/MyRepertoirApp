import 'package:flutter/material.dart';
import '../../services/media_cleanup_service.dart';

/// A dialog that displays a list of unused files.
class UnusedFilesDialog extends StatelessWidget {
  final List<UnusedFileInfo> unusedFiles;

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
            final fileInfo = unusedFiles[index];
            return ListTile(
              title: Text(fileInfo.pieceName),
              subtitle: Text('${fileInfo.fileType} - ${fileInfo.filePath}'),
            );
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
