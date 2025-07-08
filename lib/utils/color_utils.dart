import 'package:flutter/material.dart';

Color adjustColorForBrightness(Color color, Brightness brightness) {
  final HSLColor hslColor = HSLColor.fromColor(color);
  if (brightness == Brightness.dark) {
    // For dark mode, make the color darker and less saturated
    final HSLColor darkerColor = hslColor.withLightness((hslColor.lightness - 0.3).clamp(0.0, 1.0))
                                        .withSaturation((hslColor.saturation - 0.2).clamp(0.0, 1.0));
    return darkerColor.toColor();
  } else {
    // For light mode, use the original color (no lightening)
    return color;
  }
}
