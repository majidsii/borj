import 'package:borj/app/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  final calls = <String>[];
  List<ShellAction> actions() => [
    ShellAction(
      icon: Icons.calendar_month_outlined,
      label: 'تقویم',
      leading: true,
      onPressed: (_) => calls.add('cal'),
    ),
    ShellAction(
      icon: Icons.settings_outlined,
      label: 'تنظیمات',
      leading: true,
      onPressed: (_) => calls.add('set'),
    ),
    ShellAction(
      icon: Icons.add,
      label: 'ورود سریع',
      primary: true,
      onPressed: (_) => calls.add('add'),
    ),
  ];
  Widget bar({Brightness b = Brightness.light, double s = 1.0}) => glassTestApp(
    brightness: b,
    textScale: s,
    SizedBox(
      width: 358,
      child: GlassScope(
        kind: GlassLayerKind.chrome,
        child: ShellToolbar(actions: actions(), buttonSize: 44),
      ),
    ),
  );

  for (final v in glassTestVariants) {
    testWidgets('renders (${v.name})', (tester) async {
      await tester.pumpWidget(bar(b: v.brightness, s: v.textScale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('leading group on the right in RTL, primary on the left', (
    tester,
  ) async {
    await tester.pumpWidget(bar());
    final cal = tester.getCenter(find.byKey(const ValueKey('toolbar-تقویم')));
    final set = tester.getCenter(find.byKey(const ValueKey('toolbar-تنظیمات')));
    final add = tester.getCenter(
      find.byKey(const ValueKey('toolbar-ورود سریع')),
    );
    expect(cal.dx, greaterThan(set.dx));
    expect(set.dx, greaterThan(add.dx));
    expect(
      tester.getSize(find.byKey(const ValueKey('toolbar-تقویم'))),
      const Size(44, 44),
    );
  });

  testWidgets('taps call the action with a context; labels are semantic', (
    tester,
  ) async {
    calls.clear();
    await tester.pumpWidget(bar());
    await tester.tap(find.byKey(const ValueKey('toolbar-ورود سریع')));
    await tester.tap(find.byKey(const ValueKey('toolbar-تنظیمات')));
    expect(calls, ['add', 'set']);
    expect(find.bySemanticsLabel('تقویم'), findsOneWidget);
  });
}
