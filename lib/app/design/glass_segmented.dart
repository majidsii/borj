import 'package:borj/app/apple_visual/glass.dart';
import 'package:borj/app/design/pressable.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

class GlassSegment<T> {
  const GlassSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented control with an interruptible spring thumb.
class GlassSegmented<T> extends StatefulWidget {
  const GlassSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final List<GlassSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  @override
  State<GlassSegmented<T>> createState() => _GlassSegmentedState<T>();
}

/// The interruptible thumb motion: the controller value is the (fractional)
/// segment index, unbounded so the spring may overshoot.
final class _ThumbMotion {
  _ThumbMotion(TickerProvider vsync)
    : controller = AnimationController.unbounded(vsync: vsync);

  final AnimationController controller;

  void moveTo(double target, {required bool reduced}) {
    if (reduced) {
      controller.value = target;
      return;
    }
    final simulation = SpringSimulation(
      AppMotion.snappy.description,
      controller.value,
      target,
      controller.velocity,
    );
    controller.animateWith(simulation);
  }

  void dispose() => controller.dispose();
}

class _GlassSegmentedState<T> extends State<GlassSegmented<T>>
    with SingleTickerProviderStateMixin {
  static const double _gap = 2;
  static const double _padding = 3;
  static const double _height = 34;

  late final _ThumbMotion _motion = _ThumbMotion(this);

  int get _index {
    final i = widget.segments.indexWhere((s) => s.value == widget.selected);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _motion.controller.value = _index.toDouble();
  }

  @override
  void didUpdateWidget(GlassSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIndex = oldWidget.segments.indexWhere(
      (s) => s.value == oldWidget.selected,
    );
    if (oldIndex != _index) {
      _motion.moveTo(
        _index.toDouble(),
        reduced: MotionScope.reducedOf(context),
      );
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _select(int index) {
    final callback = widget.onChanged;
    if (callback == null || index < 0 || index >= widget.segments.length) {
      return;
    }
    if (index != _index) callback(widget.segments[index].value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    int? delta;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      delta = rtl ? 1 : -1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      delta = rtl ? -1 : 1;
    }
    if (delta == null) return KeyEventResult.ignored;
    final target = _index + delta;
    if (target < 0 || target >= widget.segments.length) {
      return KeyEventResult.handled;
    }
    _select(target);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final textTheme = AppTheme.of(context).text;
    final onGlass = GlassContext.isOnGlass(context);
    const capsule = AppleGlassShape.capsule();
    final count = widget.segments.length;

    TextStyle labelStyle(bool selected) => textTheme.subheadline.copyWith(
      color: selected && onGlass ? colors.thumbText : colors.text,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
    );

    final Widget thumbDecoration = onGlass
        ? DecoratedBox(
            key: const ValueKey('glass-segmented-thumb'),
            decoration: BoxDecoration(
              color: colors.thumbSurface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: colors.pressShadow,
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          )
        : const GlassInner(
            key: ValueKey('glass-segmented-thumb'),
            shape: capsule,
            child: SizedBox.expand(),
          );

    final inner = Padding(
      padding: const EdgeInsets.all(_padding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth =
              (constraints.maxWidth - _gap * (count - 1)) / count;
          final direction = Directionality.of(context);
          return SizedBox(
            height: _height,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _motion.controller,
                  builder: (context, child) => Positioned.directional(
                    textDirection: direction,
                    start: _motion.controller.value * (segmentWidth + _gap),
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: child!,
                  ),
                  child: thumbDecoration,
                ),
                Row(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      Expanded(child: _segment(i, labelStyle(i == _index))),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final track = onGlass
        ? GlassInner(shape: capsule, child: inner)
        : AppGlass(role: GlassRole.row, shape: capsule, child: inner);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: track,
      ),
    );
  }

  Widget _segment(int i, TextStyle style) {
    final segment = widget.segments[i];
    final callback = widget.onChanged;
    return Pressable(
      selected: i == _index,
      semanticLabel: segment.label,
      hoverRadius: BorderRadius.circular(999),
      onPressed: callback == null ? null : () => _select(i),
      child: SizedBox(
        height: _height,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon, size: 16, color: style.color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  segment.label,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
