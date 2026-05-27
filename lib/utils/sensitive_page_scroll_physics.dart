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
    
    // Very low velocity threshold to make even tiny flicks trigger a page change
    final double velocityThreshold = tolerance.velocity * 0.05; // 5% of the default velocity threshold

    if (velocity < -velocityThreshold) {
      // Small flick back: strongly favor the previous page
      page -= 0.7; 
    } else if (velocity > velocityThreshold) {
      // Small flick forward: strongly favor the next page
      page += 0.7;
    } else {
      // For slow drags, lower the displacement threshold from 0.5 to 0.35
      // This means moving ~35% of the way is enough to snap to the next page
      final double fraction = page - page.truncateToDouble();
      if (fraction > 0.35) {
        page = page.truncateToDouble() + 1.0;
      } else if (fraction < -0.35) {
        page = page.truncateToDouble() - 1.0;
      } else {
        page = page.roundToDouble();
      }
      return _getPixels(position, page);
    }

    return _getPixels(position, page.roundToDouble());
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
    mass: 0.4,      // Very light mass for instant response
    stiffness: 180.0, // Natural stiffness for a clean, non-mechanical snap
    damping: 20.0,    // Balanced damping for a smooth finish
  );
}
