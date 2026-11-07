import 'package:borj/app/design/patterns/spring_curve.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/widgets.dart';

final SpringCurve _springCurve = SpringCurve(AppMotion.standard);

/// Insert duration of a row: the settle time of the standard spring. A `final`
/// (not `const`) because the settle time is computed.
final Duration glassRowInsertDuration = SpringCurve.settleDuration(
  AppMotion.standard,
);

/// Remove duration of a row. Same as [glassRowInsertDuration].
final Duration glassRowRemoveDuration = glassRowInsertDuration;

const Duration _ghostDuration = Duration(milliseconds: 180);
const double _ghostScale = 0.96;

/// Duration to pass to `AnimatedList.insertItem` / `removeItem`: the spring
/// settle time, or [AppMotion.reduced] duration under Reduce Motion.
Duration glassRowDuration(BuildContext context) =>
    MotionScope.reducedOf(context)
    ? AppMotion.reduced.duration
    : glassRowInsertDuration;

/// `AnimatedList` insert builder: the slot opens with the standard spring
/// while the row fades in over [AppMotion.quick]. Reduce Motion: fade only.
Widget glassRowInsert(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  if (MotionScope.reducedOf(context)) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.reduced.curve,
      ),
      child: child,
    );
  }
  final fadeEnd =
      AppMotion.quick.duration.inMicroseconds /
      glassRowInsertDuration.inMicroseconds;
  return SizeTransition(
    axis: Axis.vertical,
    alignment: AlignmentDirectional.topStart,
    sizeFactor: CurvedAnimation(parent: animation, curve: _springCurve),
    child: FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Interval(
          0,
          fadeEnd.clamp(0.0, 1.0),
          curve: AppMotion.quick.curve,
        ),
      ),
      child: child,
    ),
  );
}

/// `AnimatedList` remove builder (the animation runs 1 to 0). The ghost fades
/// and shrinks to 0.96 over its first 180 ms while the slot collapses with the
/// standard spring. Reduce Motion: fade only; the slot goes at the end.
Widget glassRowRemove(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  if (MotionScope.reducedOf(context)) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.reduced.curve,
      ),
      child: child,
    );
  }
  final progress = ReverseAnimation(animation); // 0 to 1
  final ghostEnd =
      _ghostDuration.inMicroseconds / glassRowRemoveDuration.inMicroseconds;
  final ghost = CurvedAnimation(
    parent: progress,
    curve: Interval(0, ghostEnd.clamp(0.0, 1.0), curve: AppMotion.quick.curve),
  );
  return SizeTransition(
    axis: Axis.vertical,
    alignment: AlignmentDirectional.topStart,
    sizeFactor: ReverseAnimation(
      CurvedAnimation(parent: progress, curve: _springCurve),
    ),
    child: FadeTransition(
      opacity: ReverseAnimation(ghost),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: _ghostScale).animate(ghost),
        child: child,
      ),
    ),
  );
}
