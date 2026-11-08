import 'dart:math' as math;

import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A flat `GlassInner` pill that marks the selected item and slides between
/// targets with `AppMotion.snappy`, stretching ≤ 12 % along [axis] mid-way
/// (motion spec §3, tab switch). Reduce Motion: it jumps. Must be a child of
/// a `Stack`.
class SlidingLens extends StatefulWidget {
  const SlidingLens({
    required this.target,
    required this.axis,
    required this.shape,
    super.key,
  });

  final Rect target;
  final Axis axis;
  final AppleGlassShape shape;

  @override
  State<SlidingLens> createState() => _SlidingLensState();
}

class _SlidingLensState extends State<SlidingLens>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
    value: 1,
  )..addListener(() => setState(() {}));
  late Rect _from = widget.target;
  late Rect _to = widget.target;

  Rect get _painted {
    final p = _progress.value;
    final base = Rect.lerp(_from, _to, p)!;
    final stretch = 1 + 0.12 * math.sin(math.pi * p.clamp(0.0, 1.0));
    return widget.axis == Axis.horizontal
        ? Rect.fromCenter(
            center: base.center,
            width: base.width * stretch,
            height: base.height,
          )
        : Rect.fromCenter(
            center: base.center,
            width: base.width,
            height: base.height * stretch,
          );
  }

  @override
  void didUpdateWidget(SlidingLens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target == _to) return;
    if (MotionScope.reducedOf(context)) {
      _progress.stop();
      _from = _to = widget.target;
      _progress.value = 1;
      return;
    }
    // Start from what is painted now, without the stretch.
    _from = Rect.lerp(_from, _to, _progress.value)!;
    _to = widget.target;
    _progress
      ..value = 0
      ..animateWith(
        SpringSimulation(
          AppMotion.snappy.description,
          0,
          1,
          0,
          // Settle on the target, not within the default 1e-3 of it.
          tolerance: const Tolerance(distance: 1e-6, velocity: 1e-3),
        ),
      ).whenComplete(_settle);
  }

  void _settle() {
    if (!mounted || _progress.isAnimating) return;
    _from = _to;
    _progress.value = 1;
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _painted;
    return Positioned.fromRect(
      rect: r,
      child: IgnorePointer(
        child: GlassInner(shape: widget.shape, child: const SizedBox.expand()),
      ),
    );
  }
}
