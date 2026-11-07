import 'package:borj/app/design/app_text.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/widgets.dart';

/// A number that counts from its previous value to a new one. Screen readers
/// get only the final formatted value, never the intermediate frames.
class AnimatedNumber extends StatefulWidget {
  const AnimatedNumber({
    required this.value,
    required this.format,
    this.role = AppTextRole.body,
    this.tone = AppTextTone.primary,
    this.weight,
    this.animateIn = false,
    super.key,
  });

  final num value;
  final String Function(num value) format;
  final AppTextRole role;
  final AppTextTone tone;
  final FontWeight? weight;
  final bool animateIn;

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber> {
  late double _from;
  late double _displayed;
  bool _first = true;

  @override
  void initState() {
    super.initState();
    _from = widget.animateIn ? 0 : widget.value.toDouble();
    _displayed = _from;
  }

  @override
  void didUpdateWidget(AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // Continue from what is on screen now, not from the old target.
      _from = _displayed;
      _first = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MotionScope.reducedOf(context);
    final motion = _first && widget.animateIn
        ? AppMotion.dataEnter
        : AppMotion.dataUpdate;
    final isInt = widget.value is int;
    return Semantics(
      label: widget.format(widget.value),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: _from, end: widget.value.toDouble()),
          duration: reduced ? Duration.zero : motion.duration,
          curve: motion.curve,
          onEnd: () {
            _from = widget.value.toDouble();
            _first = false;
          },
          builder: (context, v, _) {
            _displayed = v;
            return AppText(
              widget.format(isInt ? v.round() : v),
              role: widget.role,
              tone: widget.tone,
              weight: widget.weight,
              tabular: true,
            );
          },
        ),
      ),
    );
  }
}
