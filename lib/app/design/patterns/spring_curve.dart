import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

import '../../theme/app_motion.dart';

/// A spring as a [Curve] over its settle time, so routes can use it. Values
/// may overshoot 1 (damping < 1) before landing exactly on 1 at t = 1.
final class SpringCurve extends Curve {
  SpringCurve(this.spring)
    : _settle = settleDuration(spring),
      _sim = SpringSimulation(spring.description, 0, 1, 0);

  final AppSpring spring;
  final Duration _settle;
  final SpringSimulation _sim;

  /// First time the simulation is done at tolerance 0.001, rounded up to whole
  /// milliseconds.
  static Duration settleDuration(AppSpring spring) {
    final sim = SpringSimulation(
      spring.description,
      0,
      1,
      0,
      tolerance: const Tolerance(distance: 0.001, velocity: 0.001),
    );
    var ms = 1;
    while (!sim.isDone(ms / 1000) && ms < 3000) {
      ms++;
    }
    return Duration(milliseconds: ms);
  }

  Duration get duration => _settle;

  @override
  double transformInternal(double t) =>
      _sim.x(t * _settle.inMicroseconds / Duration.microsecondsPerSecond);
}
