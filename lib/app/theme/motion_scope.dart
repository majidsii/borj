import 'package:flutter/widgets.dart';

/// Answers "should motion be reduced?" for every widget: the system flag
/// (`MediaQuery.disableAnimations`) OR the in-app «کاهش حرکت» setting, which
/// Linux needs because it has no reliable system flag.
final class MotionScope extends InheritedWidget {
  const MotionScope({
    required this.reduceMotionSetting,
    required super.child,
    super.key,
  });

  final bool reduceMotionSetting;

  static bool reducedOf(BuildContext context) {
    final system = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scope = context.dependOnInheritedWidgetOfExactType<MotionScope>();
    return system || (scope?.reduceMotionSetting ?? false);
  }

  @override
  bool updateShouldNotify(MotionScope oldWidget) =>
      oldWidget.reduceMotionSetting != reduceMotionSetting;
}
