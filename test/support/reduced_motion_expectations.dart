import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs [trigger], then pumps 16 ms frames for [span]. Every frame, it checks
/// that nothing inside [within] translates, scales or resizes. Under Reduce
/// Motion only opacity may change (motion spec §7).
Future<void> expectNoMovement(
  WidgetTester tester, {
  required Finder within,
  required Future<void> Function() trigger,
  Duration span = const Duration(milliseconds: 600),
}) async {
  await trigger();
  for (var t = Duration.zero; t < span; t += const Duration(milliseconds: 16)) {
    await tester.pump(const Duration(milliseconds: 16));
    if (within.evaluate().isEmpty) {
      return; // the subject left the tree (for example a closed sheet)
    }
    for (final w in tester.widgetList<Transform>(
      find.descendant(of: within, matching: find.byType(Transform)),
    )) {
      expect(
        w.transform.isIdentity(),
        isTrue,
        reason: 'Transform moved under Reduce Motion at $t',
      );
    }
    for (final w in tester.widgetList<FractionalTranslation>(
      find.descendant(of: within, matching: find.byType(FractionalTranslation)),
    )) {
      expect(
        w.translation,
        Offset.zero,
        reason: 'translation under Reduce Motion at $t',
      );
    }
    for (final w in tester.widgetList<SizeTransition>(
      find.descendant(of: within, matching: find.byType(SizeTransition)),
    )) {
      final v = w.sizeFactor.value;
      expect(
        v == 0 || v == 1,
        isTrue,
        reason: 'size animated under Reduce Motion at $t ($v)',
      );
    }
  }
}
