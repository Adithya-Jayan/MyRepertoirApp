import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// A screen for viewing PDF documents.
///
/// This screen utilizes the `pdfx` package to display
/// PDF files from a given local path.
class PdfViewerScreen extends StatefulWidget {
  final String pdfPath; // The local file path of the PDF document to display.

  const PdfViewerScreen({super.key, required this.pdfPath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfPath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'), // Title of the PDF viewer screen.
      ),
      body: PdfView(
        controller: _pdfController,
      ),
    );
  }
}
