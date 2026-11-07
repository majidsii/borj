import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';

/// A 52 x 32 switch. Always flat: a switch is never a glass shape.
///
/// On puts the knob at the end of the track (left in RTL).
class GlassToggle extends StatelessWidget {
  const GlassToggle({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final reduced = MotionScope.reducedOf(context);
    final duration = reduced ? Duration.zero : AppMotion.quick.duration;
    final curve = AppMotion.quick.curve;
    final callback = onChanged;

    final track = AnimatedContainer(
      key: const ValueKey('glass-toggle-track'),
      duration: duration,
      curve: curve,
      width: 52,
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? colors.switchOn : colors.switchOff,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: curve,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: DecoratedBox(
          key: const ValueKey('glass-toggle-knob'),
          decoration: BoxDecoration(
            color: colors.thumbSurface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.knobShadow,
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: const SizedBox(width: 26, height: 26),
        ),
      ),
    );

    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: Pressable(
        button: false,
        hoverRadius: BorderRadius.circular(999),
        overlayInset: const EdgeInsets.symmetric(vertical: 6),
        onPressed: callback == null ? null : () => callback(!value),
        child: SizedBox(width: 52, height: 44, child: Center(child: track)),
      ),
    );
  }
}
