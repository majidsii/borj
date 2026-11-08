import 'dart:ui' show PathMetric;

import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Round completion check. Checking springs the fill in, then draws the mark.
/// Under Reduce Motion both directions cross-fade.
class RoundCheck extends StatefulWidget {
  const RoundCheck({
    required this.checked,
    required this.onChanged,
    this.size = 24,
    this.semanticLabel,
    super.key,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final double size;
  final String? semanticLabel;

  @override
  State<RoundCheck> createState() => _RoundCheckState();
}

class _RoundCheckState extends State<RoundCheck> with TickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: widget.checked ? 1 : 0,
  );
  late final AnimationController _mark = AnimationController(
    vsync: this,
    duration: AppMotion.quick.duration,
    value: widget.checked ? 1 : 0,
  );
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    duration: AppMotion.quick.duration,
    value: widget.checked ? 1 : 0,
  );
  bool _markStarted = false;

  @override
  void initState() {
    super.initState();
    _scale.addListener(_onScale);
    _scale.addStatusListener((status) {
      // The spring settles within tolerance; land exactly on 1.
      if (status == AnimationStatus.completed && widget.checked) {
        _scale.value = 1;
      }
    });
    _opacity.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !widget.checked) {
        _scale.value = 0;
        _mark.value = 0;
      }
    });
  }

  @override
  void didUpdateWidget(RoundCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checked == widget.checked) return;
    if (widget.checked) {
      _markStarted = false;
      _mark.value = 0;
      _scale.value = 0;
      _opacity.value = 1;
      _scale.animateWith(SpringSimulation(AppMotion.soft.description, 0, 1, 0));
    } else {
      _opacity.reverse();
    }
  }

  void _onScale() {
    if (!_markStarted && widget.checked && _scale.value >= 0.95) {
      _markStarted = true;
      _mark.forward();
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _mark.dispose();
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final reduced = MotionScope.reducedOf(context);
    final size = widget.size;

    Widget ring() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.checkBorder, width: 1.5),
      ),
    );

    Widget filled(double markProgress) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.success),
      child: CustomPaint(
        painter: _MarkPainter(markProgress, colors.thumbSurface),
      ),
    );

    final Widget visual;
    if (reduced) {
      visual = AnimatedSwitcher(
        duration: AppMotion.reduced.duration,
        switchInCurve: AppMotion.reduced.curve,
        // The outgoing child runs its controller in reverse, so it needs the
        // flipped curve to ease out rather than in.
        switchOutCurve: AppMotion.reduced.curve.flipped,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: widget.checked
            ? KeyedSubtree(key: const ValueKey('checked'), child: filled(1))
            : KeyedSubtree(key: const ValueKey('unchecked'), child: ring()),
      );
    } else {
      visual = Stack(
        alignment: Alignment.center,
        children: [
          ring(),
          FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              key: const ValueKey('round-check-fill'),
              scale: _scale,
              child: AnimatedBuilder(
                animation: _mark,
                builder: (context, _) =>
                    filled(AppMotion.quick.curve.transform(_mark.value)),
              ),
            ),
          ),
        ],
      );
    }

    final onChanged = widget.onChanged;
    return Semantics(
      checked: widget.checked,
      label: widget.semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Pressable(
          button: false,
          onPressed: onChanged == null
              ? null
              : () => onChanged(!widget.checked),
          hoverRadius: BorderRadius.circular(22),
          child: Center(child: visual),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final full = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);
    final out = Path();
    for (final PathMetric m in full.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * progress), Offset.zero);
    }
    canvas.drawPath(
      out,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.progress != progress || old.color != color;
}
