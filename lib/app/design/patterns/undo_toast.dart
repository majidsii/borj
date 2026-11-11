import 'dart:async';

import 'package:flutter/material.dart';

import '../../apple_visual/glass.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion_scope.dart';
import '../app_text.dart';
import '../glass_button.dart';
import 'spring_curve.dart';

OverlayEntry? _current;
VoidCallback? _currentDismissed;

const double _rise = 16;
const double _maxWidth = 420;
const double _inset = 16;

/// Shows a toast with an undo action in the root overlay. One toast at a
/// time: showing a new one removes the old one immediately.
///
/// [onDismissed] fires exactly once when the toast goes away without undo:
/// after [visibleFor], or when another toast replaces it. Never after undo.
void showUndoToast(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  VoidCallback? onDismissed,
  String undoLabel = 'برگرداندن',
  Duration visibleFor = const Duration(seconds: 5),
  double bottomOffset = 24,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final reduced = MotionScope.reducedOf(context);
  _currentDismissed?.call();
  _currentDismissed = null;
  _current?.remove();
  _current?.dispose();
  var settled = false;
  void dismissOnce() {
    if (settled) return;
    settled = true;
    onDismissed?.call();
  }

  void undoOnce() {
    if (settled) return;
    settled = true;
    onUndo();
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => GlassOverlayContent(
      child: _UndoToast(
        message: message,
        undoLabel: undoLabel,
        onUndo: undoOnce,
        onLeft: dismissOnce,
        visibleFor: visibleFor,
        bottomOffset: bottomOffset,
        reduced: reduced,
        onGone: () {
          // A newer toast already removed and disposed this entry (its exit
          // can end in the very frame the replacement is shown).
          if (!identical(_current, entry)) return;
          _current = null;
          _currentDismissed = null;
          entry.remove();
          entry.dispose();
        },
      ),
    ),
  );
  _current = entry;
  _currentDismissed = dismissOnce;
  overlay.insert(entry);
}

final class _UndoToast extends StatefulWidget {
  const _UndoToast({
    required this.message,
    required this.undoLabel,
    required this.onUndo,
    required this.onLeft,
    required this.visibleFor,
    required this.bottomOffset,
    required this.reduced,
    required this.onGone,
  });

  final String message;
  final String undoLabel;
  final VoidCallback onUndo;
  final VoidCallback onLeft;
  final Duration visibleFor;
  final double bottomOffset;
  final bool reduced;
  final VoidCallback onGone;

  @override
  State<_UndoToast> createState() => _UndoToastState();
}

final class _UndoToastState extends State<_UndoToast>
    with SingleTickerProviderStateMixin {
  static final SpringCurve _spring = SpringCurve(AppMotion.standard);

  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final enter = widget.reduced
        ? AppMotion.reduced.duration
        : _spring.duration;
    _controller = AnimationController(
      vsync: this,
      duration: enter,
      reverseDuration: widget.reduced ? enter : AppMotion.exit(enter),
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: widget.reduced ? AppMotion.reduced.curve : _spring,
      reverseCurve: widget.reduced
          ? AppMotion.reduced.curve.flipped
          : _spring.flipped,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _leaving) widget.onGone();
    });
    unawaited(_controller.forward());
    _timer = Timer(widget.visibleFor, _leave);
  }

  void _leave({bool undone = false}) {
    if (_leaving) return;
    if (!undone) widget.onLeft();
    setState(() => _leaving = true); // also stops the toast taking taps
    _timer?.cancel();
    unawaited(_controller.reverse());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      left: _inset,
      right: _inset,
      bottom: widget.bottomOffset + media.viewPadding.bottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: AnimatedBuilder(
            animation: _curved,
            builder: (context, child) {
              final t = _curved.value;
              // The glass fades through the renderer, never a parent opacity.
              final faded = GlassVisibility(
                value: t.clamp(0.0, 1.0),
                child: child!,
              );
              if (widget.reduced) return faded;
              return Transform.translate(
                offset: Offset(0, (1 - t) * _rise),
                child: faded,
              );
            },
            child: IgnorePointer(
              ignoring: _leaving,
              child: AppGlass(
                role: GlassRole.chrome,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Semantics(
                          liveRegion: true,
                          container: true,
                          child: AppText(
                            widget.message,
                            role: AppTextRole.callout,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      GlassButton(
                        label: widget.undoLabel,
                        variant: GlassButtonVariant.plain,
                        onPressed: () {
                          if (_leaving) return;
                          widget.onUndo();
                          _leave(undone: true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
