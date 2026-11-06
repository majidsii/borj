import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Spring defined by Apple-style response (seconds) and damping ratio.
final class AppSpring {
  const AppSpring({required this.response, required this.dampingRatio});

  final double response;
  final double dampingRatio;

  SpringDescription get description => SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: math.pow(2 * math.pi / response, 2).toDouble(),
    ratio: dampingRatio,
  );
}

final class AppCurveMotion {
  const AppCurveMotion(this.duration, this.curve);

  final Duration duration;
  final Curve curve;
}

/// Motion tokens of `2026-11-06-motion-and-today-customization-design.md` §2.
/// Mapped by name from the Apple presets (`defaultSpring` → [standard],
/// `interactiveSpring` → [snappy]); the values are the spec's.
abstract final class AppMotion {
  static const Curve emphasized = Cubic(0.23, 1, 0.32, 1);

  static const AppCurveMotion press = AppCurveMotion(
    Duration(milliseconds: 120),
    emphasized,
  );
  static const AppCurveMotion quick = AppCurveMotion(
    Duration(milliseconds: 200),
    emphasized,
  );
  static const AppSpring standard = AppSpring(
    response: 0.40,
    dampingRatio: 1.0,
  );
  static const AppSpring snappy = AppSpring(response: 0.28, dampingRatio: 1.0);
  static const AppSpring soft = AppSpring(response: 0.35, dampingRatio: 0.80);
  static const AppCurveMotion dataUpdate = AppCurveMotion(
    Duration(milliseconds: 350),
    emphasized,
  );
  static const AppCurveMotion dataEnter = AppCurveMotion(
    Duration(milliseconds: 450),
    emphasized,
  );
  static const double exitFactor = 0.7;
  static const List<Duration> stagger = <Duration>[
    Duration.zero,
    Duration(milliseconds: 50),
    Duration(milliseconds: 95),
    Duration(milliseconds: 135),
    Duration(milliseconds: 170),
    Duration(milliseconds: 200),
    Duration(milliseconds: 225),
    Duration(milliseconds: 240),
  ];
  static const AppCurveMotion reduced = AppCurveMotion(
    Duration(milliseconds: 200),
    Curves.easeOut,
  );

  static Duration exit(Duration entrance) => entrance * exitFactor;

  static Duration staggerAt(int index) =>
      stagger[math.min(index, stagger.length - 1)];
}
