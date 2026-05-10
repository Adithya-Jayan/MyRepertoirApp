import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:async';
import 'package:repertoire/models/pdf_config.dart';

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

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false;
  double _scrollSpeed = 1.0; // Base speed
  Timer? _scrollTimer;
  bool _showControls = true;
  PdfDocument? _document;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollSpeed = widget.config.defaultSpeed;
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final doc = await PdfDocument.openFile(widget.pdfPath);
      if (mounted) {
        setState(() {
          _document = doc;
          _isLoaded = true;
        });
        
        // Auto-start if configured
        if (widget.config.autoScrollEnabled) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _toggleAutoScroll(true);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading PDF: $e');
    }
  }

  void _toggleAutoScroll(bool enable) {
    setState(() {
      _isAutoScrolling = enable;
    });

    _scrollTimer?.cancel();
    if (_isAutoScrolling) {
      // Use a higher frequency for smoother scrolling
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.offset;
          
          // Stop if we reached the end (with a small tolerance)
          if (currentScroll >= maxScroll - 5) {
            _toggleAutoScroll(false);
            return;
          }
          
          // Smooth scroll increment
          final nextScroll = (currentScroll + (_scrollSpeed * 0.5)).clamp(0.0, maxScroll);
          _scrollController.jumpTo(nextScroll);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _document?.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        actions: [
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
            NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                // If user starts manual scrolling, stop auto-scroll
                if (notification.direction != ScrollDirection.idle && _isAutoScrolling) {
                  _toggleAutoScroll(false);
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _document!.pagesCount,
                itemBuilder: (context, index) {
                  return _PdfPageWidget(
                    document: _document!,
                    pageNumber: index + 1,
                  );
                },
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

  const _PdfPageWidget({
    required this.document,
    required this.pageNumber,
  });

  @override
  State<_PdfPageWidget> createState() => _PdfPageWidgetState();
}

class _PdfPageWidgetState extends State<_PdfPageWidget> {
  PdfPageImage? _image;

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  Future<void> _renderPage() async {
    final page = await widget.document.getPage(widget.pageNumber);
    // Render at a decent resolution
    final image = await page.render(
      width: page.width * 1.5,
      height: page.height * 1.5,
      format: PdfPageImageFormat.jpeg,
      quality: 80,
    );
    await page.close();
    if (mounted) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const SizedBox(
        height: 500,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51), // Approximately 0.2 opacity
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.memory(
        _image!.bytes,
        fit: BoxFit.contain,
      ),
    );
  }
}
