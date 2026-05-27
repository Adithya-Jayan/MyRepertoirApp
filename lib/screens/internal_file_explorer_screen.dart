import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../database/music_piece_repository.dart';
import './pdf_viewer_screen.dart';
import './image_viewer_screen.dart';

enum FileExplorerViewMode {
  physical,
  byPiece,
  byType,
}

class InternalFileExplorerScreen extends StatefulWidget {
  const InternalFileExplorerScreen({super.key});

  @override
  State<InternalFileExplorerScreen> createState() => _InternalFileExplorerScreenState();
}

class _InternalFileExplorerScreenState extends State<InternalFileExplorerScreen> {
  FileExplorerViewMode _viewMode = FileExplorerViewMode.physical;
  
  // Navigation state
  io.Directory? _rootDirectory;
  io.Directory? _currentDirectory; // For physical mode
  final List<String> _virtualPath = []; // For virtual modes
  
  // Data
  final List<FileSystemItem> _items = [];
  Map<String, String> _pieceIdToTitle = {};
  Map<String, List<io.File>> _filesByPiece = {};
  Map<String, List<io.File>> _filesByType = {};
  
  // Selection
  final Set<String> _selectedPaths = {};
  bool _isSelectionMode = false;
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    try {
      _rootDirectory = await getApplicationDocumentsDirectory();
      _currentDirectory = _rootDirectory;
      
      final repository = MusicPieceRepository();
      final pieces = await repository.getMusicPieces();
      _pieceIdToTitle = {for (var p in pieces) p.id: p.title};
      
      await _scanFiles();
      _updateDisplayItems();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scanFiles() async {
    _filesByPiece.clear();
    _filesByType.clear();
    
    if (_rootDirectory == null) return;
    
    final mediaDir = io.Directory(p.join(_rootDirectory!.path, 'media'));
    if (!await mediaDir.exists()) return;

    final List<io.FileSystemEntity> allEntities = await mediaDir.list(recursive: true).toList();
    
    for (final entity in allEntities) {
      if (entity is io.File) {
        // By Type
        final ext = p.extension(entity.path).toLowerCase();
        String type = 'Other';
        if (['.mp3', '.wav', '.m4a', '.flac'].contains(ext)) {
          type = 'Audio';
        } else if (['.pdf'].contains(ext)) {
          type = 'PDFs';
        } else if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
          type = 'Images';
        } else if (['.mp4', '.mkv', '.mov'].contains(ext)) {
          type = 'Video';
        }
        
        _filesByType.putIfAbsent(type, () => []).add(entity);
        
        // By Piece
        final relative = p.relative(entity.path, from: mediaDir.path);
        final parts = p.split(relative);
        if (parts.isNotEmpty) {
          final pieceId = parts[0];
          final title = _pieceIdToTitle[pieceId] ?? 'Unknown Piece ($pieceId)';
          _filesByPiece.putIfAbsent(title, () => []).add(entity);
        }
      }
    }
    
    // Sort keys
    final sortedByType = Map.fromEntries(_filesByType.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    _filesByType = sortedByType;

    final sortedByPiece = Map.fromEntries(_filesByPiece.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    _filesByPiece = sortedByPiece;
  }

  void _updateDisplayItems() {
    setState(() {
      _isLoading = true;
      _items.clear();
    });

    try {
      if (_viewMode == FileExplorerViewMode.physical) {
        _loadPhysicalItems();
      } else if (_viewMode == FileExplorerViewMode.byPiece) {
        _loadByPieceItems();
      } else if (_viewMode == FileExplorerViewMode.byType) {
        _loadByTypeItems();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadPhysicalItems() {
    if (_currentDirectory == null) return;
    final entities = _currentDirectory!.listSync();
    entities.sort((a, b) {
      if (a is io.Directory && b is! io.Directory) return -1;
      if (a is! io.Directory && b is io.Directory) return 1;
      return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
    });
    
    for (final entity in entities) {
      _items.add(FileSystemItem(
        name: p.basename(entity.path),
        path: entity.path,
        isDirectory: entity is io.Directory,
        entity: entity,
      ));
    }
  }

  void _loadByPieceItems() {
    if (_virtualPath.isEmpty) {
      // Root: List of pieces
      for (final pieceTitle in _filesByPiece.keys) {
        _items.add(FileSystemItem(
          name: pieceTitle,
          path: pieceTitle,
          isDirectory: true,
          isVirtual: true,
        ));
      }
    } else {
      // Inside a piece folder
      final pieceTitle = _virtualPath[0];
      final files = _filesByPiece[pieceTitle] ?? [];
      for (final file in files) {
        _items.add(FileSystemItem(
          name: p.basename(file.path),
          path: file.path,
          isDirectory: false,
          entity: file,
        ));
      }
    }
  }

  void _loadByTypeItems() {
    if (_virtualPath.isEmpty) {
      // Root: List of types
      for (final type in _filesByType.keys) {
        _items.add(FileSystemItem(
          name: type,
          path: type,
          isDirectory: true,
          isVirtual: true,
        ));
      }
    } else {
      // Inside a type folder
      final type = _virtualPath[0];
      final files = _filesByType[type] ?? [];
      for (final file in files) {
        _items.add(FileSystemItem(
          name: p.basename(file.path),
          path: file.path,
          isDirectory: false,
          entity: file,
        ));
      }
    }
  }

  void _onItemTap(FileSystemItem item) {
    if (_isSelectionMode) {
      _toggleSelection(item.path);
      return;
    }

    if (item.isDirectory) {
      if (_viewMode == FileExplorerViewMode.physical) {
        setState(() {
          _currentDirectory = io.Directory(item.path);
        });
      } else {
        setState(() {
          _virtualPath.add(item.name);
        });
      }
      _updateDisplayItems();
    } else {
       _openFile(item.path);
    }
  }

  void _openFile(String path) {
    final extension = p.extension(path).toLowerCase();
    if (extension == '.pdf') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerScreen(pdfPath: path)));
    } else if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewerScreen(imagePath: path)));
    } else {
      // Use open_filex for other files to handle content URIs on Android
      OpenFilex.open(path);
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPaths.add(path);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _shareSelected() async {
    final List<XFile> filesToShare = [];
    for (final path in _selectedPaths) {
      final type = io.FileSystemEntity.typeSync(path);
      if (type == io.FileSystemEntityType.file) {
        filesToShare.add(XFile(path));
      }
    }

    if (filesToShare.isNotEmpty) {
      final box = context.findRenderObject() as RenderBox?;
      final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      await SharePlus.instance.share(ShareParams(
        files: filesToShare,
        sharePositionOrigin: rect,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No shareable files selected.')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Items?'),
        content: Text('Are you sure you want to delete ${_selectedPaths.length} items? This might break links in your music pieces.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        for (final path in _selectedPaths) {
          final type = io.FileSystemEntity.typeSync(path);
          if (type == io.FileSystemEntityType.file) {
            await io.File(path).delete();
          } else if (type == io.FileSystemEntityType.directory) {
            await io.Directory(path).delete(recursive: true);
          }
        }
        _selectedPaths.clear();
        _isSelectionMode = false;
        await _scanFiles();
        _updateDisplayItems();
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    if (_isSelectionMode) {
      setState(() {
        _selectedPaths.clear();
        _isSelectionMode = false;
      });
      return;
    }

    if (_viewMode == FileExplorerViewMode.physical) {
      if (_currentDirectory?.path == _rootDirectory?.path) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _currentDirectory = _currentDirectory?.parent;
      });
      _updateDisplayItems();
    } else {
      if (_virtualPath.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _virtualPath.removeLast();
      });
      _updateDisplayItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'File Explorer';
    if (_isSelectionMode) {
      title = '${_selectedPaths.length} selected';
    } else if (_viewMode == FileExplorerViewMode.physical) {
      title = p.basename(_currentDirectory?.path ?? 'Root');
    } else if (_virtualPath.isNotEmpty) {
      title = _virtualPath.last;
    } else {
      title = _viewMode == FileExplorerViewMode.byPiece ? 'All Pieces' : 'File Types';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (_isSelectionMode) ...[
              IconButton(icon: const Icon(Icons.share), onPressed: _shareSelected),
              IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelected),
            ] else ...[
              PopupMenuButton<FileExplorerViewMode>(
                icon: const Icon(Icons.grid_view),
                onSelected: (mode) {
                  setState(() {
                    _viewMode = mode;
                    _virtualPath.clear();
                    _currentDirectory = _rootDirectory;
                  });
                  _updateDisplayItems();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: FileExplorerViewMode.physical, child: Text('Physical View')),
                  const PopupMenuItem(value: FileExplorerViewMode.byPiece, child: Text('Group by Piece')),
                  const PopupMenuItem(value: FileExplorerViewMode.byType, child: Text('Group by Type')),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await _scanFiles();
                  _updateDisplayItems();
                },
              ),
            ]
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $_error', textAlign: TextAlign.center)));
    if (_items.isEmpty) return const Center(child: Text('Empty'));

    final theme = Theme.of(context);

    if ((_viewMode == FileExplorerViewMode.byPiece || _viewMode == FileExplorerViewMode.byType) && _virtualPath.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCategoryHeader(theme, _viewMode == FileExplorerViewMode.byPiece ? 'Music Pieces' : 'File Categories', 
            _viewMode == FileExplorerViewMode.byPiece ? Icons.library_music_outlined : Icons.category_outlined),
          _buildSettingsCard([
            for (final item in _items)
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.amber),
                title: Text(item.name),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => _onItemTap(item),
              ),
          ]),
        ],
      );
    }

    return ListView.builder(
      itemCount: _items.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = _items[index];
        final isSelected = _selectedPaths.contains(item.path);

        return ListTile(
          leading: _getItemLeading(item),
          title: Text(item.name, style: const TextStyle(fontSize: 14)),
          subtitle: item.isDirectory ? null : Text(_getFileSize(item.path), style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          trailing: _isSelectionMode 
            ? Checkbox(value: isSelected, onChanged: (_) => _toggleSelection(item.path)) 
            : _buildItemMenu(item),
          onTap: () => _onItemTap(item),
          onLongPress: () => _toggleSelection(item.path),
        );
      },
    );
  }

  Widget? _buildItemMenu(FileSystemItem item) {
    if (item.isVirtual) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.isDirectory && _viewMode == FileExplorerViewMode.physical)
          const Icon(Icons.chevron_right, size: 18),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) {
            if (value == 'rename') {
              _renameItem(item);
            } else if (value == 'delete') {
              _selectedPaths.clear();
              _selectedPaths.add(item.path);
              _deleteSelected();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.edit_outlined, size: 18),
                title: Text('Rename'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getItemLeading(FileSystemItem item) {
    if (item.isDirectory) {
      return const Icon(Icons.folder, color: Colors.amber);
    }
    
    final extension = p.extension(item.path).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          io.File(item.path),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          cacheWidth: 100,
          errorBuilder: (context, error, stackTrace) => Icon(_getFileIconData(item.path)),
        ),
      );
    }
    
    return Icon(_getFileIconData(item.path));
  }

  Widget _buildCategoryHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(children: children),
    );
  }

  Future<void> _renameItem(FileSystemItem item) async {
    final nameController = TextEditingController(text: item.name);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'WARNING: Renaming files may break links if not handled correctly. '
              'The app will attempt to update all piece references automatically.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'New Name'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != item.name) {
      setState(() => _isLoading = true);
      try {
        final parentPath = p.dirname(item.path);
        final newPath = p.join(parentPath, newName);
        
        if (await io.File(newPath).exists() || await io.Directory(newPath).exists()) {
          throw Exception('An item with that name already exists.');
        }

        if (item.isDirectory) {
           await io.Directory(item.path).rename(newPath);
        } else {
           await io.File(item.path).rename(newPath);
        }

        final repository = MusicPieceRepository();
        await repository.updateMediaFilePathGlobally(item.path, newPath);

        await _scanFiles();
        _updateDisplayItems();
        
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Renamed successfully.')));
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  IconData _getFileIconData(String path) {
    final extension = p.extension(path).toLowerCase();
    switch (extension) {
      case '.pdf': return Icons.picture_as_pdf;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp': return Icons.image;
      case '.mp3':
      case '.wav':
      case '.m4a':
      case '.flac': return Icons.audiotrack;
      case '.mp4':
      case '.mkv':
      case '.mov': return Icons.video_library;
      case '.json': return Icons.code;
      case '.txt':
      case '.log': return Icons.description;
      case '.zip': return Icons.archive;
      default: return Icons.insert_drive_file;
    }
  }

  String _getFileSize(String path) {
    try {
      final file = io.File(path);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return '';
    }
  }
}

class FileSystemItem {
  final String name;
  final String path;
  final bool isDirectory;
  final bool isVirtual;
  final io.FileSystemEntity? entity;

  FileSystemItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.isVirtual = false,
    this.entity,
  });
}
