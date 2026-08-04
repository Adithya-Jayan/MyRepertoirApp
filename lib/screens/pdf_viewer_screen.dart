import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:pdfrx/pdfrx.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/models/pdf_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:repertoire/utils/app_logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:repertoire/l10n/l10n.dart';
import 'package:repertoire/models/music_piece.dart';
import 'package:repertoire/models/bookmark.dart';
import 'package:repertoire/database/music_piece_repository.dart';

/// A screen for viewing PDF documents with optional auto-scroll and hyperlink support.
class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final PdfConfig config;
  final MusicPiece? musicPiece;
  final int? mediaItemIndex;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    this.config = const PdfConfig(),
    this.musicPiece,
    this.mediaItemIndex,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with TickerProviderStateMixin {
  late PdfViewerController _pdfViewerController;
  late Ticker _ticker;
  bool _isAutoScrolling = false;
  double _scrollSpeed = 1.0; // Base speed
  bool _showControls = true;
  PdfDocument? _document;
  bool _isLoaded = false;
  Duration _lastElapsed = Duration.zero;
  int _currentPage = 1;
  bool _isDraggingScrollbar = false;
  Duration _lastUpdateElapsed = Duration.zero;

  List<Bookmark> _bookmarks = [];
  final MusicPieceRepository _repository = MusicPieceRepository();
  final Uuid _uuid = Uuid();

  late AnimationController _scrollbarOpacityController;
  Timer? _scrollbarHideTimer;
  Timer? _controlsHideTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    
    if (widget.musicPiece != null && widget.mediaItemIndex != null) {
      final currentMediaId = widget.musicPiece!.mediaItems[widget.mediaItemIndex!].id;
      _bookmarks = widget.musicPiece!.bookmarks
          .where((b) => b.mediaItemId == currentMediaId || b.mediaItemId == null)
          .toList();
    }

    _pdfViewerController = PdfViewerController();
    _scrollSpeed = widget.config.defaultSpeed;
    _ticker = createTicker(_onTick);

    _scrollbarOpacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0, // Initially hidden
    );

    _pdfViewerController.addListener(_onTransformationChanged);
    _loadSavedSpeed();

    _resetControlsTimer();
    
    // Show initially, then fade out
    _showScrollbar();
  }

  void _resetControlsTimer() {
    _controlsHideTimer?.cancel();
    if (_showControls) {
      _controlsHideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetControlsTimer();
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  void _showScrollbar() {
    if (_isAutoScrolling) return; // Stay hidden while auto-scrolling

    _scrollbarOpacityController.forward();
    _scrollbarHideTimer?.cancel();
    _scrollbarHideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isDraggingScrollbar) {
        _scrollbarOpacityController.reverse();
      }
    });
  }

  void _onTransformationChanged() {
    if (!mounted || !_pdfViewerController.isReady) return;

    final newPage = _pdfViewerController.pageNumber ?? 1;
    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
    }
  }

  void _onTick(Duration elapsed) {
    if (!_isAutoScrolling || !_pdfViewerController.isReady) return;

    // Safety check to ensure layout is ready and dimensions are valid
    try {
      final viewSize = _pdfViewerController.viewSize;
      final docSize = _pdfViewerController.documentSize;
      if (viewSize.width <= 0 ||
          viewSize.height <= 0 ||
          docSize.width <= 0 ||
          docSize.height <= 0) {
        return;
      }
    } catch (_) {
      return; // Not fully laid out yet
    }

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      _lastUpdateElapsed = elapsed;
      return;
    }

    final Duration delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    final Duration updateDelta = elapsed - _lastUpdateElapsed;
    // Throttle scroll updates to ~30fps to give the rendering engine breathing room
    if (updateDelta < const Duration(milliseconds: 30)) {
      return;
    }
    _lastUpdateElapsed = elapsed;

    if (delta == Duration.zero) return;

    // 1.0 speed = 40 pixels per second
    final double pixelsPerSecond = _scrollSpeed * 40.0;
    final double moveAmount =
        pixelsPerSecond * (updateDelta.inMicroseconds / 1000000.0);

    final Matrix4 matrix = _pdfViewerController.value.clone();
    final Vector3 translation = matrix.getTranslation();

    // Note: PDF layouts scroll down, reducing Y translation
    final double newY = translation.y - moveAmount;

    // Boundary check using document size
    final double viewerHeight = _pdfViewerController.viewSize.height;
    final double totalHeight = _pdfViewerController.documentSize.height;
    final double scale = matrix.getMaxScaleOnAxis();

    if (scale <= 0 || scale.isNaN || scale.isInfinite) return;

    final double maxScroll = math.max(
      0.0,
      (totalHeight * scale) - viewerHeight,
    );

    if (-newY >= maxScroll - 5) {
      _toggleAutoScroll(false);
      matrix.setTranslationRaw(translation.x, -maxScroll, 0);
    } else {
      matrix.setTranslationRaw(translation.x, newY, 0);
    }

    _pdfViewerController.value = matrix;
  }

  Future<void> _loadSavedSpeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSpeed = prefs.getDouble(
        'pdf_scroll_speed_${widget.pdfPath.hashCode}',
      );
      if (savedSpeed != null && mounted) {
        setState(() {
          _scrollSpeed = savedSpeed;
        });
      }
    } catch (e) {
      AppLogger.log('Error loading saved PDF speed: $e');
    }
  }

  Future<void> _saveSpeed(double speed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
        'pdf_scroll_speed_${widget.pdfPath.hashCode}',
        speed,
      );
    } catch (e) {
      AppLogger.log('Error saving PDF speed: $e');
    }
  }

  void _toggleAutoScroll(bool enable) {
    if (!mounted) return;
    if (_isAutoScrolling == enable) return;

    setState(() {
      _isAutoScrolling = enable;
    });

    if (_isAutoScrolling) {
      _scrollbarHideTimer?.cancel();
      _scrollbarOpacityController.reverse();
      _lastElapsed = Duration.zero;
      _lastUpdateElapsed = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
      }
      _showScrollbar();
    }
  }

  void _updateZoom(double factor) {
    if (!_pdfViewerController.isReady) return;
    final double currentScale = _pdfViewerController.currentZoom;
    final double newScale = (currentScale * factor).clamp(
      _pdfViewerController.minScale,
      4.0,
    );

    _pdfViewerController.setZoom(_pdfViewerController.centerPosition, newScale);
  }

  void _resetZoom() {
    if (!_pdfViewerController.isReady) return;
    final double fitScale = _pdfViewerController.alternativeFitScale == null
        ? _pdfViewerController.coverScale
        : math.min(
            _pdfViewerController.coverScale,
            _pdfViewerController.alternativeFitScale!,
          );
    _pdfViewerController.setZoom(_pdfViewerController.centerPosition, fitScale);
  }

  void _handleDoubleTap() {
    if (!_pdfViewerController.isReady) return;
    final currentZoom = _pdfViewerController.currentZoom;

    // Zoom out to fit page width if we are currently zoomed in
    final double fitScale = _pdfViewerController.alternativeFitScale == null
        ? _pdfViewerController.coverScale
        : math.min(
            _pdfViewerController.coverScale,
            _pdfViewerController.alternativeFitScale!,
          );

    if (currentZoom > fitScale + 0.01) {
      _pdfViewerController.setZoom(
        _pdfViewerController.centerPosition,
        fitScale,
      );
    } else {
      _pdfViewerController.setZoom(
        _pdfViewerController.centerPosition,
        fitScale * 2.0,
      );
    }
  }

  Future<void> _jumpToPage(int pageNumber) async {
    if (!_pdfViewerController.isReady ||
        pageNumber < 1 ||
        pageNumber > _pdfViewerController.pageCount) {
      return;
    }
    await _pdfViewerController.goToPage(pageNumber: pageNumber);
  }

  void _showJumpToPageDialog() {
    if (!_pdfViewerController.isReady || _document == null) return;
    final TextEditingController controller = TextEditingController(
      text: _currentPage.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.goToPage),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.pageNumberHint(_document!.pages.length),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null) {
              _jumpToPage(page);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                _jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: Text(context.l10n.go),
          ),
        ],
      ),
    );
  }

  void _handleScrollbarDrag(DragUpdateDetails details) {
    final RenderBox? viewerBox = context.findRenderObject() as RenderBox?;
    if (viewerBox == null || !_pdfViewerController.isReady) return;

    double totalHeight;
    double scale;
    try {
      scale = _pdfViewerController.currentZoom;
      totalHeight = _pdfViewerController.documentSize.height * scale;
    } catch (_) {
      return; // Layout or document not fully ready yet
    }

    final double viewerHeight = viewerBox.size.height;
    final double maxScroll = math.max(0.0, totalHeight - viewerHeight);

    if (maxScroll <= 0) return;

    final double dragY = details.localPosition.dy;
    final double scrollPercentage = (dragY / viewerHeight).clamp(0.0, 1.0);
    final double newScrollY = scrollPercentage * maxScroll;

    final Matrix4 matrix = _pdfViewerController.value.clone();
    final Vector3 translation = matrix.getTranslation();
    matrix.setTranslationRaw(translation.x, -newScrollY, 0);
    _pdfViewerController.value = matrix;
  }

  void _saveState() async {
    if (!_isLoaded || _document == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final matrixList = _pdfViewerController.value.storage.toList();
      await prefs.setString('pdf_matrix_${widget.pdfPath}', jsonEncode(matrixList));
    } catch (e) {
      AppLogger.log('Error saving PDF state: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    if (widget.musicPiece == null || widget.mediaItemIndex == null) return;
    
    // Update the piece's bookmarks (replacing those for this media item)
    final currentMediaId = widget.musicPiece!.mediaItems[widget.mediaItemIndex!].id;
    final otherBookmarks = widget.musicPiece!.bookmarks
        .where((b) => b.mediaItemId != currentMediaId && b.mediaItemId != null)
        .toList();
    
    widget.musicPiece!.bookmarks = [...otherBookmarks, ..._bookmarks];
    
    try {
      await _repository.updateMusicPiece(widget.musicPiece!);
      AppLogger.log('PdfViewerScreen: Saved ${_bookmarks.length} bookmarks.');
    } catch (e) {
      AppLogger.log('PdfViewerScreen: Error saving bookmarks: $e');
    }
  }

  Future<void> _addBookmark() async {
    if (widget.musicPiece == null || widget.mediaItemIndex == null) return;
    
    final currentMediaId = widget.musicPiece!.mediaItems[widget.mediaItemIndex!].id;
    final newBookmark = Bookmark(
      id: _uuid.v4(),
      pageNumber: _currentPage,
      name: context.l10n.bookmarkDefaultName(_bookmarks.length + 1),
      mediaItemId: currentMediaId,
    );

    setState(() {
      _bookmarks.add(newBookmark);
      // Sort by page number if possible
      _bookmarks.sort((a, b) => (a.pageNumber ?? 0).compareTo(b.pageNumber ?? 0));
    });
    await _saveBookmarks();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark added at page $_currentPage')),
      );
    }
  }

  Future<void> _removeBookmark(String bookmarkId) async {
    setState(() {
      _bookmarks.removeWhere((b) => b.id == bookmarkId);
    });
    await _saveBookmarks();
  }

  Future<void> _renameBookmark(String bookmarkId, String newName) async {
    setState(() {
      final index = _bookmarks.indexWhere((b) => b.id == bookmarkId);
      if (index != -1) {
        _bookmarks[index] = _bookmarks[index].copyWith(name: newName);
      }
    });
    await _saveBookmarks();
  }

  void _showBookmarksSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.bookmarks,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _addBookmark();
                      setSheetState(() {});
                    },
                    icon: const Icon(Icons.bookmark_add),
                    label: Text(context.l10n.addBookmark),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _bookmarks.isEmpty
                        ? Center(child: Text(context.l10n.noBookmarksAddedYet))
                        : ListView.builder(
                            itemCount: _bookmarks.length,
                            itemBuilder: (context, index) {
                              final bookmark = _bookmarks[index];
                              return Dismissible(
                                key: Key(bookmark.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  _removeBookmark(bookmark.id);
                                  setSheetState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.l10n.bookmarkDismissed(bookmark.name)),
                                    ),
                                  );
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.bookmark),
                                  title: Text(bookmark.name),
                                  subtitle: Text('Page ${bookmark.pageNumber ?? 1}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () async {
                                      final controller = TextEditingController(text: bookmark.name);
                                      final newName = await showDialog<String>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(context.l10n.renameBookmark),
                                          content: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            onSubmitted: (value) => Navigator.of(context).pop(value),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text(context.l10n.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(controller.text),
                                              child: Text(context.l10n.rename),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (newName != null && newName.isNotEmpty && newName != bookmark.name) {
                                        await _renameBookmark(bookmark.id, newName);
                                        setSheetState(() {});
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    if (bookmark.pageNumber != null) {
                                      _pdfViewerController.goToPage(pageNumber: bookmark.pageNumber!);
                                    }
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _saveState();
    WakelockPlus.disable();
    _scrollbarHideTimer?.cancel();
    _scrollbarOpacityController.dispose();
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _ticker.dispose();
    _pdfViewerController.removeListener(_onTransformationChanged);
    _document?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_showControls,
            child: AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.8) ?? Colors.black87,
              elevation: 0,
              title: Text(context.l10n.pdfViewer),
              actions: [
                if (widget.musicPiece != null && widget.mediaItemIndex != null)
                  IconButton(
                    icon: const Icon(Icons.bookmarks),
                    onPressed: _showBookmarksSheet,
                    tooltip: context.l10n.bookmarks,
                  ),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () => _updateZoom(0.8),
                  tooltip: context.l10n.zoomOut,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () => _updateZoom(1.2),
                  tooltip: context.l10n.zoomIn,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_backup_restore),
                  onPressed: _resetZoom,
                  tooltip: context.l10n.resetZoom,
                ),
                if (widget.config.autoScrollEnabled && !_showControls)
                  IconButton(
                    icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
                    onPressed: () => _toggleAutoScroll(!_isAutoScrolling),
                    tooltip: _isAutoScrolling
                        ? context.l10n.pause
                        : context.l10n.play,
                  ),
                if (widget.config.autoScrollEnabled)
                  IconButton(
                    icon: Icon(
                      _showControls ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _toggleControls,
                    tooltip: context.l10n.toggleControls,
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            onTap: _toggleControls,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                if (_showControls) _resetControlsTimer();
                _showScrollbar();
                if (_isAutoScrolling) {
                  _toggleAutoScroll(false);
                }
              },
              onPointerMove: (_) => _showScrollbar(),
              onPointerUp: (_) => _showScrollbar(),
              onPointerSignal: (pointerSignal) {
                _showScrollbar();
                if (pointerSignal is PointerScrollEvent) {
                  final isControlPressed =
                      HardwareKeyboard.instance.isControlPressed;
                  if (isControlPressed) {
                    final zoomDelta = pointerSignal.scrollDelta.dy > 0
                        ? 0.9
                        : 1.1;
                    _updateZoom(zoomDelta);
                  }
                }
              },
              child: PdfViewer.file(
                widget.pdfPath,
                controller: _pdfViewerController,
                params: PdfViewerParams(
                  margin: 8.0,
                  minScale: 0.5,
                  useAlternativeFitScaleAsMinScale: false,
                  behaviorControlParams: const PdfViewerBehaviorControlParams(
                    pageImageCachingDelay: Duration.zero,
                    partialImageLoadingDelay: Duration.zero,
                  ),
                  onViewerReady: (document, controller) async {
                    if (mounted) {
                      setState(() {
                        _isLoaded = true;
                        _document = document;
                      });
                      
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final savedMatrixStr = prefs.getString('pdf_matrix_${widget.pdfPath}');
                        if (savedMatrixStr != null) {
                          final List<dynamic> decoded = jsonDecode(savedMatrixStr);
                          final List<double> matrixList = decoded.map((e) => (e as num).toDouble()).toList();
                          controller.value = Matrix4.fromList(matrixList);
                          return; // State restored successfully
                        }
                      } catch (e) {
                        AppLogger.log('Error loading PDF state: $e');
                      }
                      
                      // Explicitly set zoom to fit page width/height to avoid starting zoomed in
                      final double fitScale = controller.alternativeFitScale == null
                          ? controller.coverScale
                          : math.min(
                              controller.coverScale,
                              controller.alternativeFitScale!,
                            );
                      controller.setZoom(controller.centerPosition, fitScale);
                    }
                  },
                  onPageChanged: (page) {
                    if (page != null && mounted) {
                      setState(() {
                        _currentPage = page;
                      });
                    }
                  },
                  linkHandlerParams: PdfLinkHandlerParams(
                    onLinkTap: (link) {
                      if (link.url != null) {
                        launchUrl(link.url!);
                      } else if (link.dest != null) {
                        _pdfViewerController.goToDest(link.dest!);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          if (!_isLoaded) const Center(child: CircularProgressIndicator()),

          // Scrollbar implementation
          if (_isLoaded && _document != null)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onVerticalDragStart: (_) {
                  setState(() => _isDraggingScrollbar = true);
                  _showScrollbar();
                },
                onVerticalDragEnd: (_) {
                  setState(() => _isDraggingScrollbar = false);
                  _showScrollbar();
                },
                onVerticalDragUpdate: (details) {
                  _showScrollbar();
                  _handleScrollbarDrag(details);
                },
                child: FadeTransition(
                  opacity: _scrollbarOpacityController,
                  child: Container(
                    width: 20,
                    color: Colors.transparent,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Safe check for documentSize and value availability
                        double totalHeight;
                        double scale;
                        Vector3 translation;
                        try {
                          final docSize = _pdfViewerController.documentSize;
                          final Matrix4 matrix = _pdfViewerController.value;
                          translation = matrix.getTranslation();
                          scale = matrix.getMaxScaleOnAxis();
                          totalHeight = docSize.height * scale;
                        } catch (_) {
                          return const SizedBox.shrink(); // Not fully laid out yet
                        }

                        final double viewerHeight = constraints.maxHeight;
                        if (totalHeight <= viewerHeight) {
                          return const SizedBox.shrink();
                        }

                        final double scrollPercentage =
                            (-translation.y / (totalHeight - viewerHeight))
                                .clamp(0.0, 1.0);
                        final double thumbHeight = math.max(
                          40.0,
                          (viewerHeight / totalHeight) * viewerHeight,
                        );
                        final double thumbTop =
                            scrollPercentage * (viewerHeight - thumbHeight);

                        return Stack(
                          children: [
                            Positioned(
                              top: thumbTop,
                              right: 2,
                              child: Container(
                                width: 8,
                                height: thumbHeight,
                                decoration: BoxDecoration(
                                  color: _isDraggingScrollbar
                                      ? Colors.black87
                                      : Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          if (_showControls &&
              widget.config.autoScrollEnabled &&
              _document != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildScrollOverlay(),
            )
          else if (_isLoaded && _document != null)
            // Page indicator when controls are hidden
            Positioned(
              bottom: 20,
              right: 40,
              child: GestureDetector(
                onTap: _showJumpToPageDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    context.l10n.pageIndicator(
                      _currentPage,
                      _document!.pages.length,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollOverlay() {
    if (_document == null) return const SizedBox.shrink();
    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () => _toggleAutoScroll(!_isAutoScrolling),
            ),
            Text(
              context.l10n.speed,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Expanded(
              child: Slider(
                value: _scrollSpeed,
                min: 0.1,
                max: 10.0,
                divisions: 99,
                onChanged: (value) {
                  setState(() {
                    _scrollSpeed = value;
                  });
                  _saveSpeed(value);
                  if (_isAutoScrolling) _toggleAutoScroll(true);
                },
              ),
            ),
            GestureDetector(
              onTap: _showJumpToPageDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.pageIndicator(
                    _currentPage,
                    _document!.pages.length,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
