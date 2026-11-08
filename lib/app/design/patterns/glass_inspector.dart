import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/patterns/spring_curve.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

/// The desktop inspector (`MacTasks`, `MacMoney`): a sheet-glass panel at the
/// leading edge of the content (left in RTL). Slides in with `standard`, out
/// with `standard` × exitFactor; Reduce Motion fades it through the renderer.
class GlassInspector extends StatefulWidget {
  const GlassInspector({
    required this.open,
    required this.child,
    this.onClose,
    super.key,
  });

  final bool open;
  final Widget child;
  final VoidCallback? onClose;

  static const double width = 360;

  @override
  State<GlassInspector> createState() => _GlassInspectorState();
}

class _GlassInspectorState extends State<GlassInspector>
    with SingleTickerProviderStateMixin {
  static final SpringCurve _spring = SpringCurve(AppMotion.standard);
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        value: widget.open ? 1 : 0,
        duration: _spring.duration,
        reverseDuration: _spring.duration * AppMotion.exitFactor,
      )..addStatusListener((_) {
        if (mounted) setState(() {});
      });
  late final CurvedAnimation _reducedFade = CurvedAnimation(
    parent: _c,
    curve: AppMotion.reduced.curve,
    reverseCurve: AppMotion.reduced.curve.flipped,
  );
  late final CurvedAnimation _slide = CurvedAnimation(
    parent: _c,
    curve: _spring,
    reverseCurve: Curves.easeOut.flipped,
  );

  @override
  void didUpdateWidget(GlassInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    final reduced = MotionScope.reducedOf(context);
    _c
      ..duration = reduced ? AppMotion.reduced.duration : _spring.duration
      ..reverseDuration = reduced
          ? AppMotion.reduced.duration
          : _spring.duration * AppMotion.exitFactor;
    if (widget.open) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _reducedFade.dispose();
    _slide.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.isDismissed) return const SizedBox.shrink();
    final reduced = MotionScope.reducedOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final glass = GlassScope(
      kind: GlassLayerKind.sheet,
      child: AppGlass(
        key: const ValueKey('inspector'),
        role: GlassRole.sheet,
        shape: const AppleGlassShape.rounded(20),
        child: SizedBox(width: GlassInspector.width, child: widget.child),
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      child: glass,
      builder: (context, child) {
        if (reduced) {
          return GlassVisibility(
            value: _reducedFade.value.clamp(0.0, 1.0),
            child: child!,
          );
        }
        // Off-screen side: left in RTL (the content's end edge), right in LTR.
        final dx =
            (1 - _slide.value) * (GlassInspector.width + 16) * (isRtl ? -1 : 1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
