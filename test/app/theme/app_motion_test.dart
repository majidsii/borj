import 'dart:math' as math;

import 'package:borj/app/theme/app_motion.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spring tokens follow the spec table', () {
    expect(AppMotion.standard.response, 0.40);
    expect(AppMotion.standard.dampingRatio, 1.0);
    expect(AppMotion.snappy.response, 0.28);
    expect(AppMotion.snappy.dampingRatio, 1.0);
    expect(AppMotion.soft.response, 0.35);
    expect(AppMotion.soft.dampingRatio, 0.80);
  });

  test('stiffness is (2π/response)² with mass 1', () {
    final d = AppMotion.standard.description;
    expect(d.mass, 1);
    expect(d.stiffness, closeTo(math.pow(2 * math.pi / 0.40, 2), 1e-9));
    // critically damped: c = 2·ζ·√(k·m)
    expect(d.damping, closeTo(2 * math.sqrt(d.stiffness), 1e-9));
  });

  test('curve tokens', () {
    expect(AppMotion.press.duration, const Duration(milliseconds: 120));
    expect(AppMotion.quick.duration, const Duration(milliseconds: 200));
    expect(AppMotion.press.curve, const Cubic(0.23, 1, 0.32, 1));
    expect(AppMotion.dataUpdate.duration, const Duration(milliseconds: 350));
    expect(AppMotion.dataEnter.duration, const Duration(milliseconds: 450));
    expect(AppMotion.reduced.duration, const Duration(milliseconds: 200));
    expect(AppMotion.reduced.curve, Curves.easeOut);
  });

  test('exit is 70% of the entrance; stagger caps at 240 ms', () {
    expect(
      AppMotion.exit(const Duration(milliseconds: 400)),
      const Duration(milliseconds: 280),
    );
    expect(AppMotion.staggerAt(0), Duration.zero);
    expect(AppMotion.staggerAt(3), const Duration(milliseconds: 135));
    expect(AppMotion.staggerAt(20), const Duration(milliseconds: 240));
  });
}
