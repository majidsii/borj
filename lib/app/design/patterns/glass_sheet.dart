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
      Navigator.of(context, rootNavigator: true).pop(result);
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
    // The glass fades through the renderer (GlassVisibility), never through
    // a parent opacity, which would seed an extra backdrop capture.
    // CurvedAnimation keeps the direction a run started with, so closing a
    // reduced open mid-run does not jump. Reverse is ease-out in time.
    if (!reduced) return child;
    final fade = _fade ??= CurvedAnimation(
      parent: animation,
      curve: AppMotion.reduced.curve,
      reverseCurve: AppMotion.reduced.curve.flipped,
    );
    return AnimatedBuilder(
      animation: fade,
      builder: (context, child) =>
          GlassVisibility(value: fade.value, child: child!),
      child: child,
    );
  }

  CurvedAnimation? _fade;

  @override
  void dispose() {
    _fade?.dispose();
    super.dispose();
  }
}

final class _GlassSheetFrame extends StatefulWidget {
  const _GlassSheetFrame({required this.route});

  final _GlassSheetRoute<dynamic> route;

  @override
  State<_GlassSheetFrame> createState() => _GlassSheetFrameState();
}

/// Where the sheet is painted: centre, scale per axis (after the 0.2 clamp)
/// and opacity. Every paint path records the pose it painted, so a grab can
/// freeze exactly what the user sees.
@immutable
final class _Pose {
  const _Pose(this.cx, this.cy, this.sx, this.sy, this.opacity);

  final double cx;
  final double cy;
  final double sx;
  final double sy;
  final double opacity;

  _Pose shifted(double dy) => _Pose(cx, cy + dy, sx, sy, opacity);

  Rect rect(Size child) => Rect.fromCenter(
    center: Offset(cx, cy),
    width: child.width * sx,
    height: child.height * sy,
  );

  /// Interpolates the rect edges (not centre and scale), so each edge, and
  /// the top in particular, moves monotonically.
  static _Pose lerp(_Pose a, _Pose b, double t, Size child) {
    final r = Rect.lerp(a.rect(child), b.rect(child), t)!;
    return _Pose(
      r.center.dx,
      r.center.dy,
      r.width / child.width,
      r.height / child.height,
      (a.opacity + (b.opacity - a.opacity) * t).clamp(0.0, 1.0),
    );
  }
}

enum _Phase { idle, dragging, settling, dismissing }

/// State shared by the frame and its paint delegate.
final class _SheetPaintState {
  /// The pose of the last paint.
  _Pose painted = const _Pose(0, 0, 1, 1, 1);

  /// Pose frozen at grab, and the vertical drag since (px, never negative).
  _Pose grab = const _Pose(0, 0, 1, 1, 1);
  final ValueNotifier<double> dragDy = ValueNotifier<double>(0);

  /// Pose and route-controller value at release (spring-back / dismiss start).
  _Pose release = const _Pose(0, 0, 1, 1, 1);
  double releaseValue = 1;

  /// Resting pose centre of the last paint (spring-back distance).
  double restingCy = 0;
}

final class _GlassSheetFrameState extends State<_GlassSheetFrame>
    with SingleTickerProviderStateMixin {
  final GlobalKey _sheetKey = GlobalKey();
  final ValueNotifier<_Phase> _phase = ValueNotifier<_Phase>(_Phase.idle);
  final _SheetPaintState _paint = _SheetPaintState();
  late final CurvedAnimation _curved;

  /// Spring-back progress from the release pose (0) to the resting pose (1).
  late final AnimationController _settle;

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
    _settle = AnimationController(vsync: this)..addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _curved.dispose();
    _settle.dispose();
    _phase.dispose();
    _paint.dragDy.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    final phase = _phase.value;
    if (status == AnimationStatus.reverse &&
        (phase == _Phase.settling || phase == _Phase.dragging)) {
      // The route is closing (Escape, barrier, GlassSheet.close, system back)
      // while we hold a pose of our own: close from what is on screen.
      _settle.stop();
      _paint.release = _paint.painted;
      _paint.releaseValue = _controller.value;
      _phase.value = _Phase.dismissing;
      return;
    }
    if (_phase.value == _Phase.settling &&
        _settle.status == AnimationStatus.completed &&
        _controller.status == AnimationStatus.completed) {
      _phase.value = _Phase.idle; // identical pose at t = 1
    }
  }

  double? get _sheetHeight => _sheetKey.currentContext?.size?.height;

  void _dragStart(DragStartDetails details) {
    if (!widget.route.isActive || _phase.value == _Phase.dismissing) return;
    _controller.stop();
    _settle.stop();
    // Freeze what is on screen; never rebase through the open curve.
    _paint.grab = _paint.painted;
    _paint.dragDy.value = 0;
    _phase.value = _Phase.dragging;
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_phase.value != _Phase.dragging || !widget.route.isActive) return;
    // primaryDelta is in the sheet's scaled local space; the sheet must move
    // 1:1 with the finger on screen.
    _paint.dragDy.value = math.max(
      0,
      _paint.dragDy.value + (details.primaryDelta ?? 0) * _paint.grab.sy,
    );
  }

  void _dragEnd(DragEndDetails details) => _release(details.velocity);

  void _dragCancel() => _release(Velocity.zero);

  void _release(Velocity velocity) {
    if (_phase.value != _Phase.dragging || !widget.route.isActive) return;
    final h = _sheetHeight;
    final vy = velocity.pixelsPerSecond.dy * _paint.grab.sy; // screen px/s
    final dy = _paint.dragDy.value;
    _paint.release = _paint.grab.shifted(dy);
    _paint.releaseValue = _controller.value;
    // Relative to the drag (not to how open the sheet is): releasing without
    // dragging always reopens it.
    if (h == null ||
        h <= 0 ||
        vy > _dismissVelocity ||
        1 - dy / h < _dismissFraction) {
      _phase.value = _Phase.dismissing;
      Navigator.of(context).pop();
      return;
    }
    if (widget.route.reduced) {
      // No translation under Reduce Motion: the sheet is back at rest at once.
      _phase.value = _Phase.idle;
    } else {
      _phase.value = _Phase.settling;
      _settle.value = 0;
      // Progress velocity along the way back to rest.
      final distance = _paint.restingCy - _paint.release.cy;
      _settle.animateWith(
        SpringSimulation(
          AppMotion.soft.description,
          0,
          1,
          distance.abs() < 1 ? 0 : vy / distance,
        ),
      );
    }
    if (!_controller.isCompleted) {
      _controller.animateTo(1, curve: Curves.linear); // scrim back to full
    }
  }

  /// The sheet's opacity for this frame, applied to its glass through
  /// [GlassVisibility]. Mirrors the pose opacity the delegate records.
  double _visibility() {
    if (widget.route.reduced) return 1; // the route fades it instead
    return switch (_phase.value) {
      _Phase.dragging => _paint.grab.opacity,
      _Phase.settling =>
        _paint.release.opacity + (1 - _paint.release.opacity) * _settle.value,
      _Phase.dismissing => _paint.release.opacity,
      _Phase.idle => (_curved.value / 0.3).clamp(0.0, 1.0),
    };
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
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _curved,
                _controller,
                _phase,
                _settle,
              ]),
              builder: (context, child) =>
                  GlassVisibility(value: _visibility(), child: child!),
              child: Flow(
                clipBehavior: Clip.none,
                delegate: _SheetFlowDelegate(
                  animation: _curved,
                  controller: _controller,
                  phase: _phase,
                  settle: _settle,
                  paint: _paint,
                  origin: route.origin,
                  reduced: route.reduced,
                  bottomInset: bottom + _inset,
                  topInset: media.viewPadding.top + _inset,
                ),
                children: [sheet],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out the sheet at the bottom and paints it: grown from the trigger
/// (spring), from the frozen grab pose while the user drags (1:1), springing
/// back from the release pose, or closing from it. Every path records the
/// pose it painted into [paint].
final class _SheetFlowDelegate extends FlowDelegate {
  _SheetFlowDelegate({
    required this.animation,
    required this.controller,
    required this.phase,
    required this.settle,
    required this.paint,
    required this.origin,
    required this.reduced,
    required this.bottomInset,
    required this.topInset,
  }) : super(
         repaint: Listenable.merge([
           animation,
           controller,
           phase,
           settle,
           paint.dragDy,
         ]),
       );

  final Animation<double> animation;
  final AnimationController controller;
  final ValueNotifier<_Phase> phase;
  final Animation<double> settle;
  final _SheetPaintState paint;
  final Rect? origin;
  final bool reduced;
  final double bottomInset;
  final double topInset;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    final width = math.max(
      0.0,
      math.min(_maxSheetWidth, constraints.maxWidth - 2 * _inset),
    );
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: math.max(0, constraints.maxHeight - bottomInset - topInset),
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final size = context.size;
    final child = context.getChildSize(0)!;
    final base = Offset(
      (size.width - child.width) / 2,
      size.height - bottomInset - child.height,
    );
    final resting = _Pose(
      base.dx + child.width / 2,
      base.dy + child.height / 2,
      1,
      1,
      1,
    );
    final _Pose pose;
    switch (phase.value) {
      case _Phase.dragging:
        pose = paint.grab.shifted(paint.dragDy.value);
      case _Phase.settling:
        pose = _Pose.lerp(paint.release, resting, settle.value, child);
      case _Phase.dismissing:
        final from = paint.releaseValue;
        // Reduced motion: hold the release pose; the route fades it out.
        final p = reduced
            ? 0.0
            : from <= 0
            ? 1.0
            : ((from - controller.value) / from).clamp(0.0, 1.0);
        final distance = size.height - paint.release.rect(child).top;
        pose = paint.release.shifted(p * distance);
      case _Phase.idle:
        pose = reduced ? resting : _grownPose(size, child, resting);
    }
    paint.painted = pose;
    paint.restingCy = resting.cy;
    context.paintChild(
      0,
      transform: Matrix4.translationValues(pose.cx, pose.cy, 0)
        ..scaleByDouble(pose.sx, pose.sy, 1, 1)
        ..translateByDouble(-child.width / 2, -child.height / 2, 0, 1),
    ); // opacity is applied to the glass by GlassVisibility, not here
  }

  _Pose _grownPose(Size size, Size child, _Pose resting) {
    final t = animation.value;
    final target = Rect.fromCenter(
      center: Offset(resting.cx, resting.cy),
      width: child.width,
      height: child.height,
    );
    final from =
        origin ??
        Rect.fromLTWH(
          (size.width - child.width) / 2,
          size.height - 40,
          child.width,
          40,
        );
    final lerped = Rect.lerp(from, target, t)!;
    return _Pose(
      lerped.center.dx,
      lerped.center.dy,
      math.max(0.2, lerped.width / target.width),
      math.max(0.2, lerped.height / target.height),
      (t / 0.3).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(_SheetFlowDelegate old) =>
      old.animation != animation ||
      old.controller != controller ||
      old.phase != phase ||
      old.settle != settle ||
      old.paint != paint ||
      old.origin != origin ||
      old.reduced != reduced ||
      old.bottomInset != bottomInset ||
      old.topInset != topInset;

  @override
  bool shouldRelayout(_SheetFlowDelegate old) =>
      old.bottomInset != bottomInset || old.topInset != topInset;
}
