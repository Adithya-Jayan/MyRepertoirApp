import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:pdfx/pdfx.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/models/pdf_config.dart';
import 'dart:math' as math;

/// A screen for viewing PDF documents with optional auto-scroll.
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

class _PdfViewerScreenState extends State<PdfViewerScreen> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _contentKey = GlobalKey();
  late Ticker _ticker;
  bool _isAutoScrolling = false;
  double _scrollSpeed = 1.0; // Base speed
  bool _showControls = true;
  PdfDocument? _document;
  bool _isLoaded = false;
  double? _defaultAspectRatio;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _scrollSpeed = widget.config.defaultSpeed;
    _ticker = createTicker(_onTick);
    _loadDocument();
    _loadSavedSpeed();
  }

  void _onTick(Duration elapsed) {
    if (!_isAutoScrolling) return;

    final Duration delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    if (delta == Duration.zero) return;

    // 1.0 speed = 40 pixels per second
    final double pixelsPerSecond = _scrollSpeed * 40.0;
    final double moveAmount = pixelsPerSecond * (delta.inMicroseconds / 1000000.0);

    final Matrix4 matrix = _transformationController.value.clone();
    final Vector3 translation = matrix.getTranslation();
    
    // Note: InteractiveViewer translation is negative of scroll offset
    final double newY = translation.y - moveAmount;
    
    // Boundary check using the content size
    final RenderBox? contentBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? viewerBox = context.findRenderObject() as RenderBox?;
    
    if (contentBox != null && viewerBox != null) {
      final double contentHeight = contentBox.size.height;
      final double viewerHeight = viewerBox.size.height;
      final double scale = matrix.getMaxScaleOnAxis();
      
      // The maximum translation is -(totalScaledHeight - viewerHeight)
      // We add a small buffer (5 pixels) to ensure we stop reliably
      final double maxScroll = math.max(0.0, (contentHeight * scale) - viewerHeight);
      
      if (-newY >= maxScroll - 5) {
        debugPrint('[PDFScroll] End reached. Stopping.');
        _toggleAutoScroll(false);
        matrix.setTranslationRaw(translation.x, -maxScroll, 0);
      } else {
        matrix.setTranslationRaw(translation.x, newY, 0);
      }
    } else {
      matrix.setTranslationRaw(translation.x, newY, 0);
    }
    
    _transformationController.value = matrix;
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
      debugPrint('Error loading saved PDF speed: $e');
    }
  }

  Future<void> _saveSpeed(double speed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('pdf_scroll_speed_${widget.pdfPath.hashCode}', speed);
    } catch (e) {
      debugPrint('Error saving PDF speed: $e');
    }
  }

  Future<void> _loadDocument() async {
    try {
      final doc = await PdfDocument.openFile(widget.pdfPath);
      
      double? ratio;
      try {
        final page1 = await doc.getPage(1);
        ratio = page1.width / page1.height;
        await page1.close();
      } catch (e) {
        debugPrint('Error getting first page aspect ratio: $e');
      }

      if (mounted) {
        setState(() {
          _document = doc;
          _defaultAspectRatio = ratio;
          _isLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading PDF: $e');
    }
  }

  void _toggleAutoScroll(bool enable) {
    if (!mounted) return;
    if (_isAutoScrolling == enable) return;

    setState(() {
      _isAutoScrolling = enable;
    });

    if (_isAutoScrolling) {
      _lastElapsed = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
      }
    }
  }

  void _updateZoom(double factor) {
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    final double newScale = (currentScale * factor).clamp(1.0, 4.0);
    
    final Matrix4 matrix = _transformationController.value.clone();
    final Vector3 translation = matrix.getTranslation();
    
    // Update scale while preserving translation
    // Note: We use identity and then scale/translate to ensure a clean matrix
    matrix.setIdentity();
    matrix.scaleByVector3(Vector3(newScale, newScale, 1.0));
    matrix.setTranslation(translation);
    
    setState(() {
      _transformationController.value = matrix;
    });
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  void dispose() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _ticker.dispose();
    _document?.close();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
          if (_isLoaded && _document != null)
            Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  final isControlPressed = HardwareKeyboard.instance.isControlPressed;
                  if (isControlPressed) {
                    final zoomDelta = pointerSignal.scrollDelta.dy > 0 ? 0.9 : 1.1;
                    _updateZoom(zoomDelta);
                  }
                }
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                constrained: false, // Allows the Column to be its natural size
                onInteractionStart: (_) {
                  _toggleAutoScroll(false);
                },
                child: SizedBox(
                  width: screenWidth,
                  child: Column(
                    key: _contentKey,
                    children: List.generate(_document!.pagesCount, (index) {
                      return _PdfPageWidget(
                        document: _document!,
                        pageNumber: index + 1,
                        defaultAspectRatio: _defaultAspectRatio,
                        transformationController: _transformationController,
                      );
                    }),
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          if (_showControls && widget.config.autoScrollEnabled)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildScrollOverlay(),
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
            Text(
              '${_scrollSpeed.toStringAsFixed(1)}x',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfPageWidget extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;
  final double? defaultAspectRatio;
  final TransformationController transformationController;

  const _PdfPageWidget({
    required this.document,
    required this.pageNumber,
    this.defaultAspectRatio,
    required this.transformationController,
  });

  @override
  State<_PdfPageWidget> createState() => _PdfPageWidgetState();
}

class _PdfPageWidgetState extends State<_PdfPageWidget> {
  PdfPageImage? _image;
  double? _aspectRatio;
  bool _isRendering = false;

  @override
  void initState() {
    super.initState();
    widget.transformationController.addListener(_checkVisibility);
    // Initial check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_checkVisibility);
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted || _isRendering || _image != null) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset position = box.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Add a buffer of one screen height above and below
    if (position.dy < screenHeight * 2 && position.dy + box.size.height > -screenHeight) {
      _renderPage();
    }
  }

  Future<void> _renderPage() async {
    if (_isRendering || _image != null) return;
    
    setState(() => _isRendering = true);
    
    try {
      final page = await widget.document.getPage(widget.pageNumber);
      
      if (mounted) {
        setState(() {
          _aspectRatio = page.width / page.height;
        });
      }

      if (!mounted) {
        await page.close();
        return;
      }
      
      final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final double renderScale = math.max(2.0, devicePixelRatio);

      final image = await page.render(
        width: page.width * renderScale,
        height: page.height * renderScale,
        format: PdfPageImageFormat.jpeg,
        quality: 90,
      );
      await page.close();
      if (mounted) {
        setState(() {
          _image = image;
          _isRendering = false;
        });
      }
    } catch (e) {
      debugPrint('Error rendering page ${widget.pageNumber}: $e');
      if (mounted) setState(() => _isRendering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_image == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = Image.memory(
        _image!.bytes,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }

    final ratio = _aspectRatio ?? widget.defaultAspectRatio ?? 0.707;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: ratio,
        child: content,
      ),
    );
  }
}



