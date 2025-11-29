import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.5), // Stronger tint at bottom
            colorScheme.surface.withValues(alpha: 0.0),  // Fade to transparent at top
          ],
          stops: const [0.0, 0.7], // Gradient fades out towards the top
        ),
      ),
    );
  }
}
