import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Press feedback, hover, focus ring and button semantics for any child.
///
/// Pointer-down scales the child to 0.97 over [AppMotion.press]; under Reduce
/// Motion it fades to 0.7 instead. [hoverRadius] rounds the hover and focus
/// overlays to the child's own shape.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.selected = false,
    this.button = true,
    this.hoverRadius = BorderRadius.zero,
    this.overlayInset = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool selected;
  final bool button;
  final BorderRadius hoverRadius;

  /// Insets the hover and focus overlays from the child's bounds, so they
  /// follow the visible shape when the child is padded for hit testing.
  final EdgeInsets overlayInset;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  final FocusNode _focusNode = FocusNode(debugLabel: 'Pressable');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && (_pressed || _hovered)) {
      _pressed = false;
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final reduced = MotionScope.reducedOf(context);

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_hovered)
          Positioned.fill(
            left: widget.overlayInset.left,
            top: widget.overlayInset.top,
            right: widget.overlayInset.right,
            bottom: widget.overlayInset.bottom,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('pressable-hover'),
                decoration: BoxDecoration(
                  color: colors.selection.withValues(alpha: 0.5),
                  borderRadius: widget.hoverRadius,
                ),
              ),
            ),
          ),
        if (_focused)
          Positioned.fill(
            left: widget.overlayInset.left,
            top: widget.overlayInset.top,
            right: widget.overlayInset.right,
            bottom: widget.overlayInset.bottom,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('pressable-focus'),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.accent, width: 2),
                  borderRadius: widget.hoverRadius,
                ),
              ),
            ),
          ),
      ],
    );

    content = reduced
        ? AnimatedOpacity(
            opacity: _pressed ? 0.7 : 1,
            duration: AppMotion.reduced.duration,
            curve: AppMotion.reduced.curve,
            child: content,
          )
        : AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: AppMotion.press.duration,
            curve: AppMotion.press.curve,
            child: content,
          );

    content = Listener(
      onPointerDown: _enabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: content,
      ),
    );

    content = MouseRegion(
      onEnter: _enabled
          ? (event) {
              if (event.kind == PointerDeviceKind.mouse && !_hovered) {
                setState(() => _hovered = true);
              }
            }
          : null,
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: content,
    );

    content = FocusableActionDetector(
      enabled: _enabled,
      focusNode: _focusNode,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: content,
    );

    content = Semantics(
      button: widget.button,
      enabled: _enabled,
      selected: widget.selected ? true : null,
      focusable: _enabled,
      focused: _enabled ? _focusNode.hasFocus : null,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onPressed,
      onFocus: _enabled ? _focusNode.requestFocus : null,
      child: content,
    );

    return _enabled ? content : Opacity(opacity: 0.4, child: content);
  }
}
