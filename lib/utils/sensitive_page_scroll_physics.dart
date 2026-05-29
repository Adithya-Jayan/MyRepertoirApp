import 'package:flutter/material.dart';

/// A custom scroll physics for [PageView] that is more sensitive to swipes than [PageScrollPhysics].
/// 
/// It lowers the velocity and distance thresholds required to snap to the next page,
/// making the gallery navigation feel more fluid and responsive without oscillation.
class SensitivePageScrollPhysics extends ScrollPhysics {
  const SensitivePageScrollPhysics({super.parent});

  @override
  SensitivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SensitivePageScrollPhysics(parent: buildParent(ancestor));
  }

  double _getPage(ScrollMetrics position) {
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    return page * position.viewportDimension;
  }

  double _getTargetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = _getPage(position);

    // Extremely low velocity threshold to ensure almost any flick triggers a page change
    final double velocityThreshold = tolerance.velocity * 0.01; // 1% of the default velocity threshold

    if (velocity < -velocityThreshold) {
      // Flick back: snap to the previous page index
      // Using round(page - 0.5) ensures we go to the immediately adjacent page without overshooting
      page = (page - 0.5).roundToDouble();
    } else if (velocity > velocityThreshold) {
      // Flick forward: snap to the next page index
      // Using round(page + 0.5) ensures we go to the immediately adjacent page without overshooting
      page = (page + 0.5).roundToDouble();
    } else {
      // For slow drags, even 15% of the way is enough to snap to the next page
      // This makes the UI feel very "eager" to move
      final double fraction = page - page.truncateToDouble();
      if (fraction > 0.15) {
        page = page.truncateToDouble() + 1.0;
      } else if (fraction < -0.15) {
        page = page.truncateToDouble() - 1.0;
      } else {
        page = page.roundToDouble();
      }
    }

    // Convert page index back to pixels and CLAMP to prevent harsh boundary bounces
    final double target = _getPixels(position, page);
    return target.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, tolerance, velocity);

    if (target != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => true;

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.5,      // Slightly more mass for a grounded feel
    stiffness: 120.0, // Natural stiffness for a smooth, decisive snap
    damping: 20.0,    // Overdamped to ensure no oscillation or jitter
  );
}
