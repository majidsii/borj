import 'package:dashboard_shakhsi/app/apple_visual/review/glass_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows four sample rows and a no-reference notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: GlassReviewScreen(referenceDir: null)),
    );
    await tester.pump();
    for (final label in <String>[
      'Top-bar capsule',
      'Tab control',
      'Circle button',
      'Dialog surface',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('No reference images'), findsOneWidget);
  });
}
