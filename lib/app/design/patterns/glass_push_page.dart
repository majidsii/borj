import 'package:borj/app/shell/window_class.dart';
import 'package:borj/app/theme/app_background.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A pushed page: Cupertino slide and back gesture on compact (direction
/// aware), a scrim over the covered page, instant on medium/expanded and
/// under Reduce Motion (a page holds glass, so it never cross-fades).
class GlassPushPage<T> extends Page<T> {
  const GlassPushPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _GlassPushRoute<T>(this);
}

class _GlassPushRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  _GlassPushRoute(GlassPushPage<T> page) : super(settings: page);

  GlassPushPage<T> get _page => settings as GlassPushPage<T>;

  static bool _animated(BuildContext context) =>
      WindowClass.of(context) == WindowClass.compact &&
      !MotionScope.reducedOf(context);

  bool get _animatedNow {
    final ctx = navigator?.context;
    return ctx != null && _animated(ctx);
  }

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      _animatedNow ? super.transitionDuration : Duration.zero;

  @override
  Duration get reverseTransitionDuration =>
      _animatedNow ? super.reverseTransitionDuration : Duration.zero;

  @override
  bool get popGestureEnabled => _animatedNow && super.popGestureEnabled;

  // The mixin's framework barrier (0x18000000) would stack under the token
  // scrim; the scrim alone dims.
  @override
  Color? get barrierColor => null;

  // Slide-only parallax for the covered route, whatever its own transition
  // (only Cupertino routes would do it by themselves).
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _animatedNow ? CupertinoPageTransition.delegatedTransition : null;

  @override
  bool didPop(T? result) {
    // Durations are read once at controller creation; refresh the reverse one
    // so a window resize or Reduce Motion since the push does not freeze it.
    controller?.reverseDuration = reverseTransitionDuration;
    return super.didPop(result);
  }

  @override
  Widget buildContent(BuildContext context) => AppBackground(
    kind: AppBackgroundKind.phone,
    child: Material(type: MaterialType.transparency, child: _page.child),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!_animated(context)) return child;
    final scrim = AppTheme.of(context).colors.scrim;
    // The incoming route dims what it covers: a full-screen scrim BEHIND the
    // sliding page (only the page slides), so pages built with a plain
    // `builder:` are dimmed too. The route stays opaque; Flutter keeps
    // painting the covered route until the transition completes.
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) =>
                animation.isDismissed || animation.isCompleted
                ? const SizedBox.shrink()
                : ColoredBox(
                    key: const ValueKey('push-scrim'),
                    color: scrim.withValues(alpha: scrim.a * animation.value),
                  ),
          ),
        ),
        super.buildTransitions(context, animation, secondaryAnimation, child),
      ],
    );
  }
}
