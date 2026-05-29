import 'package:flutter/material.dart';

/// A custom scroll physics for [PageView] that is more sensitive to swipes than [PageScrollPhysics].
/// 
/// It lowers the velocity and distance thresholds required to snap to the next page,
/// making the gallery navigation feel more fluid and responsive without oscillation.
class SensitivePageScrollPhysics extends PageScrollPhysics {
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
      // Flick back (towards smaller indices): snap to the previous page
      // Using ceil - 0.9 ensures that if we are exactly on page 1.0, we go to 0.1
      page = page.ceilToDouble() - 0.9;
    } else if (velocity > velocityThreshold) {
      // Flick forward (towards larger indices): snap to the next page
      // Using floor + 0.9 ensures that if we are exactly on page 0.0, we go to 0.9
      page = page.floorToDouble() + 0.9;
    } else {
      // For slow drags, even 25% of the way is enough to snap to the next page
      // This is the "eager" behavior the user wants to keep.
      final double roundPage = page.roundToDouble();
      if ((page - roundPage).abs() > 0.25) {
        page = page > roundPage ? roundPage + 1.0 : roundPage - 1.0;
      } else {
        page = roundPage;
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
}
