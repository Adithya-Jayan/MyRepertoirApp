import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import '../../services/media_cleanup_service.dart';
import '../../screens/pdf_viewer_screen.dart';
import '../../screens/image_viewer_screen.dart';

import 'package:repertoire/l10n/l10n.dart';

/// A dialog that displays a list of unused files with previews and piece names.
class UnusedFilesDialog extends StatelessWidget {
  final List<UnusedFileInfo> unusedFiles;

  const UnusedFilesDialog({super.key, required this.unusedFiles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.folder_delete_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(context.l10n.unusedMediaDetails),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                context
                    .l10n
                    .theFollowingFilesAreNotReferencedByAnyPiecesAndCanBe,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: unusedFiles.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final fileInfo = unusedFiles[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    leading: _getFileLeading(fileInfo),
                    title: Text(
                      fileInfo.pieceName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.fileTypeAndName(
                            fileInfo.fileType,
                            p.basename(fileInfo.filePath),
                          ),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getFileSize(context, fileInfo.filePath),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onTap: () => _openFile(context, fileInfo.filePath),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.close),
        ),
      ],
    );
  }

  Widget _getFileLeading(UnusedFileInfo fileInfo) {
    final extension = p.extension(fileInfo.filePath).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: io.File(fileInfo.filePath).existsSync()
            ? Image.file(
                io.File(fileInfo.filePath),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                cacheWidth: 100,
                errorBuilder: (context, error, stackTrace) =>
                    _getIconForExtension(extension),
              )
            : _getIconForExtension(extension),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _getIconForExtension(extension),
    );
  }

  Widget _getIconForExtension(String extension) {
    IconData iconData;
    Color color;

    switch (extension) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red.shade400;
        break;
      case '.mp3':
      case '.wav':
      case '.m4a':
        iconData = Icons.audiotrack;
        color = Colors.blue.shade400;
        break;
      case '.mp4':
      case '.mov':
        iconData = Icons.video_library;
        color = Colors.purple.shade400;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey.shade400;
    }

    return Icon(iconData, color: color, size: 24);
  }

  String _getFileSize(BuildContext context, String path) {
    try {
      final file = io.File(path);
      if (!file.existsSync()) return context.l10n.fileMissing;
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return '';
    }
  }

  void _openFile(BuildContext context, String path) {
    final extension = p.extension(path).toLowerCase();
    if (extension == '.pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PdfViewerScreen(pdfPath: path)),
      );
    } else if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(imagePath: path),
        ),
      );
    } else {
      OpenFilex.open(path);
    }
  }
}
