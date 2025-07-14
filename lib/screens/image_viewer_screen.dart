import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// A screen for viewing images with zoom and pan capabilities.
///
/// This screen utilizes the `photo_view` package to provide an interactive
/// image viewing experience.
class ImageViewerScreen extends StatelessWidget {
  final String imagePath; // The local file path of the image to display.

  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Viewer'), // Title of the image viewer screen.
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)), // Load image from the provided file path.
      ),
    );
  }
}