import 'package:flutter/material.dart';

class DotPatternBackground extends StatelessWidget {
  const DotPatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotPainter(
        dotColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08), // Subtle dots
        gridSize: 30, // Distance between dot centers
        dotRadius: 1, // Radius of each dot
      ),
      child: Container(), // Empty container to occupy space
    );
  }
}

class _DotPainter extends CustomPainter {
  final Color dotColor;
  final double gridSize;
  final double dotRadius;

  _DotPainter({
    required this.dotColor,
    required this.gridSize,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
           oldDelegate.gridSize != gridSize ||
           oldDelegate.dotRadius != dotRadius;
  }
}
