import 'package:borj/app/theme/motion_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<bool> _reduced(
  WidgetTester tester, {
  required bool system,
  required bool setting,
}) async {
  late bool value;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: system),
      child: MotionScope(
        reduceMotionSetting: setting,
        child: Builder(
          builder: (context) {
            value = MotionScope.reducedOf(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return value;
}

void main() {
  testWidgets('system flag OR app setting', (tester) async {
    expect(await _reduced(tester, system: false, setting: false), isFalse);
    expect(await _reduced(tester, system: true, setting: false), isTrue);
    expect(await _reduced(tester, system: false, setting: true), isTrue);
  });

  testWidgets('without a scope only the system flag counts', (tester) async {
    late bool value;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            value = MotionScope.reducedOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(value, isTrue);
  });

  testWidgets('dependents rebuild when the setting changes', (tester) async {
    var builds = 0;
    late bool value;
    final child = Builder(
      builder: (context) {
        builds++;
        value = MotionScope.reducedOf(context);
        return const SizedBox();
      },
    );
    Widget app({required bool setting}) => MediaQuery(
      data: const MediaQueryData(),
      child: MotionScope(reduceMotionSetting: setting, child: child),
    );

    await tester.pumpWidget(app(setting: false));
    expect(value, isFalse);
    final first = builds;

    await tester.pumpWidget(app(setting: false));
    expect(builds, first);

    await tester.pumpWidget(app(setting: true));
    expect(builds, first + 1);
    expect(value, isTrue);
  });
}
