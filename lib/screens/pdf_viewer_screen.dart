import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// A screen for viewing PDF documents.
///
/// This screen utilizes the `pdfrx` package to display
/// PDF files from a given local path.
class PdfViewerScreen extends StatelessWidget {
  final String pdfPath; // The local file path of the PDF document to display.

  const PdfViewerScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'), // Title of the PDF viewer screen.
      ),
      body: PdfViewer.file(pdfPath), // Display the PDF from the file path.
    );
  }
}