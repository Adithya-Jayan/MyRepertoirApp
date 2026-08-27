import 'package:flutter/material.dart';

/// A screen for viewing a piece's lyrics as plain, selectable text.
class LyricsViewerScreen extends StatelessWidget {
  final String lyrics;
  final String pieceTitle;

  const LyricsViewerScreen({
    super.key,
    required this.lyrics,
    required this.pieceTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(pieceTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            lyrics,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
