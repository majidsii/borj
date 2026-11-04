// SPIKE EXCEPTION: see ../all_glass_kit.dart.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Lays out a glass shape at an animated rect that glides to [target] with a
/// springy liquid stretch.
///
/// Two springs drive the rect: a stiff "head" edge that leads and a softer
/// "tail" edge that lags. The shape is the union of both, so it elongates in
/// the direction of travel and then settles into [target]. Must be placed
/// directly inside a [Stack]. Ignores pointer events.
class LiquidFollower extends StatefulWidget {
  const LiquidFollower({
    required this.target,
    required this.builder,
    super.key,
  });

  final Rect target;
  final Widget Function(BuildContext context, Rect rect) builder;

  @override
  State<LiquidFollower> createState() => _LiquidFollowerState();
}

class _LiquidFollowerState extends State<LiquidFollower>
    with TickerProviderStateMixin {
  static final SpringDescription _headSpring = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 24,
  );
  static final SpringDescription _tailSpring = SpringDescription(
    mass: 1,
    stiffness: 170,
    damping: 20,
  );

  late final AnimationController _head = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late final AnimationController _tail = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late Rect _headFrom = widget.target;
  late Rect _tailFrom = widget.target;
  late Rect _to = widget.target;

  Rect _lerp(Rect a, Rect b, double t) {
    return Rect.fromPoints(
      Offset(a.left + (b.left - a.left) * t, a.top + (b.top - a.top) * t),
      Offset(
        a.right + (b.right - a.right) * t,
        a.bottom + (b.bottom - a.bottom) * t,
      ),
    );
  }

  Rect get _headRect => _lerp(_headFrom, _to, _head.value);
  Rect get _tailRect => _lerp(_tailFrom, _to, _tail.value);

  @override
  void didUpdateWidget(LiquidFollower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target == _to) {
      return;
    }
    final headNow = _headRect;
    final tailNow = _tailRect;
    _to = widget.target;
    if (MediaQuery.disableAnimationsOf(context)) {
      _headFrom = _to;
      _tailFrom = _to;
      _head.value = 1;
      _tail.value = 1;
      return;
    }
    _headFrom = headNow;
    _tailFrom = tailNow;
    _head.value = 0;
    _tail.value = 0;
    unawaited(_head.animateWith(SpringSimulation(_headSpring, 0, 1, 0)));
    unawaited(_tail.animateWith(SpringSimulation(_tailSpring, 0, 1, 0)));
  }

  @override
  void dispose() {
    _head.dispose();
    _tail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_head, _tail]),
          builder: (context, _) {
            final rect = _headRect.expandToInclude(_tailRect);
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fromRect(
                  rect: rect,
                  child: widget.builder(context, rect),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
