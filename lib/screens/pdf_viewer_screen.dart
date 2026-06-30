import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:pdfrx/pdfrx.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/models/pdf_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:repertoire/utils/app_logger.dart';

/// A screen for viewing PDF documents with optional auto-scroll and hyperlink support.
class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final PdfConfig config;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    this.config = const PdfConfig(),
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> with TickerProviderStateMixin {
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

  late AnimationController _scrollbarOpacityController;
  Timer? _scrollbarHideTimer;

  @override
  void initState() {
    super.initState();
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
    
    // Show initially, then fade out
    _showScrollbar();
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

    final Duration delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    if (delta == Duration.zero) return;

    // 1.0 speed = 40 pixels per second
    final double pixelsPerSecond = _scrollSpeed * 40.0;
    final double moveAmount = pixelsPerSecond * (delta.inMicroseconds / 1000000.0);

    final Matrix4 matrix = _pdfViewerController.value.clone();
    final Vector3 translation = matrix.getTranslation();
    
    // Note: PDF layouts scroll down, reducing Y translation
    final double newY = translation.y - moveAmount;
    
    // Boundary check using document size
    final double viewerHeight = _pdfViewerController.viewSize.height;
    final double totalHeight = _pdfViewerController.documentSize.height;
    final double scale = matrix.getMaxScaleOnAxis();
    
    final double maxScroll = math.max(0.0, (totalHeight * scale) - viewerHeight);
    
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
      final savedSpeed = prefs.getDouble('pdf_scroll_speed_${widget.pdfPath.hashCode}');
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
      await prefs.setDouble('pdf_scroll_speed_${widget.pdfPath.hashCode}', speed);
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
    final double newScale = (currentScale * factor).clamp(_pdfViewerController.minScale, 4.0);
    
    _pdfViewerController.setZoom(
      _pdfViewerController.centerPosition,
      newScale,
    );
  }

  void _resetZoom() {
    if (!_pdfViewerController.isReady) return;
    _pdfViewerController.goTo(Matrix4.identity());
  }

  void _handleDoubleTap() {
    if (!_pdfViewerController.isReady) return;
    if (_pdfViewerController.value != Matrix4.identity()) {
      _resetZoom();
    } else {
      _pdfViewerController.setZoom(_pdfViewerController.centerPosition, 2.0);
    }
  }

  Future<void> _jumpToPage(int pageNumber) async {
    if (!_pdfViewerController.isReady || pageNumber < 1 || pageNumber > _pdfViewerController.pageCount) return;
    await _pdfViewerController.goToPage(pageNumber: pageNumber);
  }

  void _showJumpToPageDialog() {
    if (!_pdfViewerController.isReady || _document == null) return;
    final TextEditingController controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-${_document!.pages.length})',
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                _jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _handleScrollbarDrag(DragUpdateDetails details) {
    final RenderBox? viewerBox = context.findRenderObject() as RenderBox?;
    if (viewerBox == null || !_pdfViewerController.isReady) return;

    final double viewerHeight = viewerBox.size.height;
    final double scale = _pdfViewerController.currentZoom;
    final double totalHeight = _pdfViewerController.documentSize.height * scale;
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

  @override
  void dispose() {
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
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _updateZoom(0.8),
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _updateZoom(1.2),
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
          if (widget.config.autoScrollEnabled && !_showControls)
            IconButton(
              icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
              onPressed: () => _toggleAutoScroll(!_isAutoScrolling),
              tooltip: _isAutoScrolling ? 'Pause' : 'Play',
            ),
          if (widget.config.autoScrollEnabled)
            IconButton(
              icon: Icon(_showControls ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showControls = !_showControls),
              tooltip: 'Toggle Controls',
            ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
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
                  final isControlPressed = HardwareKeyboard.instance.isControlPressed;
                  if (isControlPressed) {
                    final zoomDelta = pointerSignal.scrollDelta.dy > 0 ? 0.9 : 1.1;
                    _updateZoom(zoomDelta);
                  }
                }
              },
              child: PdfViewer.file(
                widget.pdfPath,
                controller: _pdfViewerController,
                params: PdfViewerParams(
                  margin: 8.0,
                  onViewerReady: (document, controller) {
                    if (mounted) {
                      setState(() {
                        _isLoaded = true;
                        _document = document;
                      });
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
          
          if (!_isLoaded)
            const Center(child: CircularProgressIndicator()),

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
                        final Matrix4 matrix = _pdfViewerController.value;
                        final Vector3 translation = matrix.getTranslation();
                        final double scale = matrix.getMaxScaleOnAxis();

                        final double viewerHeight = constraints.maxHeight;
                        final double totalHeight = _pdfViewerController.documentSize.height * scale;
                        
                        if (totalHeight <= viewerHeight) return const SizedBox.shrink();

                        final double scrollPercentage = (-translation.y / (totalHeight - viewerHeight)).clamp(0.0, 1.0);
                        final double thumbHeight = math.max(40.0, (viewerHeight / totalHeight) * viewerHeight);
                        final double thumbTop = scrollPercentage * (viewerHeight - thumbHeight);

                        return Stack(
                          children: [
                            Positioned(
                              top: thumbTop,
                              right: 2,
                              child: Container(
                                width: 8,
                                height: thumbHeight,
                                decoration: BoxDecoration(
                                  color: _isDraggingScrollbar ? Colors.white70 : Colors.white38,
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

          if (_showControls && widget.config.autoScrollEnabled)
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '$_currentPage / ${_document!.pages.length}',
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
    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: () => _toggleAutoScroll(!_isAutoScrolling),
            ),
            const Text('Speed:', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                  '$_currentPage / ${_document!.pages.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
