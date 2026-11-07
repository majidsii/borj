import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:borj/core/formatting/persian_number.dart';
import 'package:flutter/material.dart';

enum ProgressTone { accent, success, warn, danger }

/// A capsule progress bar. The fill starts at the start edge (right in RTL).
class ProgressTrack extends StatefulWidget {
  const ProgressTrack({
    required this.value,
    this.tone = ProgressTone.accent,
    this.height = 6,
    this.animateIn = false,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final ProgressTone tone;
  final double height;
  final bool animateIn;
  final String? semanticLabel;

  @override
  State<ProgressTrack> createState() => _ProgressTrackState();
}

class _ProgressTrackState extends State<ProgressTrack> {
  bool _first = true;

  @override
  void didUpdateWidget(ProgressTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _first = false;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final tone = widget.tone;
    final height = widget.height;
    final animateIn = widget.animateIn;
    final semanticLabel = widget.semanticLabel;
    final colors = AppTheme.of(context).colors;
    final reduced = MotionScope.reducedOf(context);
    final fraction = value.clamp(0.0, 1.0);
    final color = switch (tone) {
      ProgressTone.accent => colors.accent,
      ProgressTone.success => colors.success,
      ProgressTone.warn => colors.warn,
      ProgressTone.danger => colors.danger,
    };
    final motion = animateIn && _first
        ? AppMotion.dataEnter
        : AppMotion.dataUpdate;
    final radius = BorderRadius.circular(height / 2);

    return Semantics(
      label: semanticLabel,
      value: formatPersianPercent(fraction),
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.hairline,
            borderRadius: radius,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: animateIn ? 0 : fraction,
              end: fraction,
            ),
            duration: reduced ? Duration.zero : motion.duration,
            curve: motion.curve,
            builder: (context, factor, _) => FractionallySizedBox(
              widthFactor: factor,
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                key: const ValueKey('progress-fill'),
                decoration: BoxDecoration(color: color, borderRadius: radius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
