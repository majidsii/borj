import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../apple_visual/glass.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion_scope.dart';
import 'spring_curve.dart';

/// Opens a glass sheet. [origin] is the trigger's global rect; the sheet grows
/// from it. Resolves with the value given to [GlassSheet.close].
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Rect? origin,
  String? semanticLabel,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    _GlassSheetRoute<T>(
      builder: builder,
      origin: origin,
      reduced: MotionScope.reducedOf(context),
      scrim: AppTheme.of(context).colors.scrim,
      semanticLabel: semanticLabel,
    ),
  );
}

abstract final class GlassSheet {
  static void close<T>(BuildContext context, [T? result]) =>
      Navigator.of(context).pop(result);
}

/// Vertical drag velocity (px/s) above which a release dismisses.
const double _dismissVelocity = 110;

/// Open fraction below which a release dismisses.
const double _dismissFraction = 0.6;

const double _inset = 8;
const double _maxSheetWidth = 560;

final class _GlassSheetRoute<T> extends PopupRoute<T> {
  _GlassSheetRoute({
    required this.builder,
    required this.origin,
    required this.reduced,
    required this.scrim,
    this.semanticLabel,
  });

  final WidgetBuilder builder;
  final Rect? origin;
  final bool reduced;
  final Color scrim;
  final String? semanticLabel;

  static final SpringCurve _open = SpringCurve(AppMotion.soft);
  static final SpringCurve _close = SpringCurve(AppMotion.standard);

  @override
  Duration get transitionDuration =>
      reduced ? AppMotion.reduced.duration : _open.duration;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? AppMotion.reduced.duration : AppMotion.exit(_close.duration);

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => scrim; // the modal barrier fades with the route

  @override
  String? get barrierLabel => 'بستن';

  AnimationController get sheetController => controller!;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
  ) {
    return GlassOverlayContent(child: _GlassSheetFrame(route: this));
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    // Under reduced motion only opacity changes. Otherwise the frame places
    // the sheet itself (grow from origin, or 1:1 under the finger).
    return reduced ? FadeTransition(opacity: animation, child: child) : child;
  }
}

final class _GlassSheetFrame extends StatefulWidget {
  const _GlassSheetFrame({required this.route});

  final _GlassSheetRoute<dynamic> route;

  @override
  State<_GlassSheetFrame> createState() => _GlassSheetFrameState();
}

final class _GlassSheetFrameState extends State<_GlassSheetFrame> {
  final GlobalKey _sheetKey = GlobalKey();

  /// True while the user drags, and until the sheet is back fully open: the
  /// sheet then follows the controller 1:1 with a plain translation.
  final ValueNotifier<bool> _userDriven = ValueNotifier<bool>(false);
  late final CurvedAnimation _curved;

  AnimationController get _controller => widget.route.sheetController;

  @override
  void initState() {
    super.initState();
    _curved = CurvedAnimation(
      parent: widget.route.animation!,
      curve: _GlassSheetRoute._open,
      reverseCurve: _GlassSheetRoute._close.flipped,
    );
    _controller.addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _curved.dispose();
    _userDriven.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _userDriven.value) {
      _userDriven.value = false; // identical pose at t = 1
    }
  }

  double? get _sheetHeight => _sheetKey.currentContext?.size?.height;

  void _dragStart(DragStartDetails details) {
    _controller.stop();
    _userDriven.value = true;
  }

  void _dragUpdate(DragUpdateDetails details) {
    final h = _sheetHeight;
    if (h == null || h <= 0) return;
    _controller.value -= (details.primaryDelta ?? 0) / h;
  }

  void _dragEnd(DragEndDetails details) {
    final h = _sheetHeight;
    final vy = details.velocity.pixelsPerSecond.dy;
    if (h == null ||
        h <= 0 ||
        vy > _dismissVelocity ||
        _controller.value < _dismissFraction) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.route.reduced) {
      _controller.animateTo(
        1,
        duration: AppMotion.reduced.duration,
        curve: AppMotion.reduced.curve,
      );
    } else {
      _controller.animateWith(
        SpringSimulation(
          AppMotion.soft.description,
          _controller.value,
          1,
          -vy / h,
        ),
      );
    }
  }

  void _dragCancel() {
    if (_controller.value >= 1) {
      _userDriven.value = false;
    } else {
      _dragEnd(DragEndDetails());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context).colors;
    final media = MediaQuery.of(context);
    final bottom = math.max(media.viewPadding.bottom, media.viewInsets.bottom);
    final route = widget.route;

    final sheet = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _dragStart,
      onVerticalDragUpdate: _dragUpdate,
      onVerticalDragEnd: _dragEnd,
      onVerticalDragCancel: _dragCancel,
      child: KeyedSubtree(
        key: _sheetKey,
        child: AppGlass(
          role: GlassRole.sheet,
          shape: const AppleGlassShape.rounded(AppRadii.sheet),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.hairline,
                    borderRadius: BorderRadius.circular(AppRadii.capsule),
                  ),
                  child: const SizedBox(width: 36, height: 5),
                ),
              ),
              Flexible(child: Builder(builder: route.builder)),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: route.semanticLabel != null,
      label: route.semanticLabel,
      explicitChildNodes: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: Material(
            type: MaterialType.transparency,
            child: Flow(
              clipBehavior: Clip.none,
              delegate: _SheetFlowDelegate(
                animation: _curved,
                controller: _controller,
                userDriven: _userDriven,
                origin: route.origin,
                reduced: route.reduced,
                bottomInset: bottom + _inset,
              ),
              children: [sheet],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out the sheet at the bottom and paints it: grown from the trigger
/// (spring), 1:1 under the finger, or still (reduced motion; the route fades).
final class _SheetFlowDelegate extends FlowDelegate {
  _SheetFlowDelegate({
    required this.animation,
    required this.controller,
    required this.userDriven,
    required this.origin,
    required this.reduced,
    required this.bottomInset,
  }) : super(repaint: Listenable.merge([animation, controller, userDriven]));

  final Animation<double> animation;
  final AnimationController controller;
  final ValueNotifier<bool> userDriven;
  final Rect? origin;
  final bool reduced;
  final double bottomInset;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.min(_maxSheetWidth, constraints.maxWidth - 2 * _inset),
        maxHeight: math.max(0, constraints.maxHeight - bottomInset - _inset),
      );

  @override
  void paintChildren(FlowPaintingContext context) {
    final size = context.size;
    final child = context.getChildSize(0)!;
    final base = Offset(
      (size.width - child.width) / 2,
      size.height - bottomInset - child.height,
    );
    if (userDriven.value) {
      context.paintChild(
        0,
        transform: Matrix4.translationValues(
          base.dx,
          base.dy + (1 - controller.value) * child.height,
          0,
        ),
      );
      return;
    }
    if (reduced) {
      context.paintChild(
        0,
        transform: Matrix4.translationValues(base.dx, base.dy, 0),
      );
      return;
    }
    final t = animation.value;
    final target = base & child;
    final from =
        origin ??
        Rect.fromLTWH(
          (size.width - child.width) / 2,
          size.height - 40,
          child.width,
          40,
        );
    final lerped = Rect.lerp(from, target, t)!;
    final sx = math.max(0.2, lerped.width / target.width);
    final sy = math.max(0.2, lerped.height / target.height);
    final matrix = Matrix4.translationValues(
      lerped.center.dx,
      lerped.center.dy,
      0,
    )..scaleByDouble(sx, sy, 1, 1);
    matrix.translateByDouble(-child.width / 2, -child.height / 2, 0, 1);
    context.paintChild(
      0,
      transform: matrix,
      opacity: (t / 0.3).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(_SheetFlowDelegate old) =>
      old.animation != animation ||
      old.controller != controller ||
      old.userDriven != userDriven ||
      old.origin != origin ||
      old.reduced != reduced ||
      old.bottomInset != bottomInset;

  @override
  bool shouldRelayout(_SheetFlowDelegate old) => old.bottomInset != bottomInset;
}
