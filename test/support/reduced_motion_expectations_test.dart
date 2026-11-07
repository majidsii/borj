import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reduced_motion_expectations.dart';

void main() {
  testWidgets('fails when the subject is not in the tree', (tester) async {
    await tester.pumpWidget(const SizedBox());
    await expectLater(
      expectNoMovement(
        tester,
        within: find.byKey(const ValueKey('missing')),
        trigger: () async {},
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets('passes for a static subject', (tester) async {
    await tester.pumpWidget(
      const SizedBox(key: ValueKey('subject'), child: SizedBox(width: 4)),
    );
    await expectNoMovement(
      tester,
      within: find.byKey(const ValueKey('subject')),
      trigger: () async {},
      span: const Duration(milliseconds: 64),
    );
  });

  testWidgets('ignores the static flip of a directional Icon in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          key: ValueKey('subject'),
          child: Icon(Icons.chevron_left),
        ),
      ),
    );
    expect(
      find.descendant(of: find.byType(Icon), matching: find.byType(Transform)),
      findsOneWidget,
    );
    await expectNoMovement(
      tester,
      within: find.byKey(const ValueKey('subject')),
      trigger: () async {},
      span: const Duration(milliseconds: 64),
    );
  });
}
