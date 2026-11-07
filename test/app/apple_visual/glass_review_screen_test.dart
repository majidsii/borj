import 'dart:io';

import 'package:borj/app/apple_visual/review/design_review_samples.dart';
import 'package:borj/app/apple_visual/review/glass_review_screen.dart';
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

  testWidgets('design section renders every sample in light and dark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: GlassReviewScreen(referenceDir: null)),
    );
    await tester.pump();
    for (final sample in designReviewSamples) {
      await tester.scrollUntilVisible(
        find.text(sample.label),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(sample.label), findsOneWidget);
    }
    final boards = <String, int>{};
    for (final s in designReviewSamples) {
      boards.update(s.board, (n) => n + 1, ifAbsent: () => 1);
    }
    for (final e in boards.entries) {
      await tester.scrollUntilVisible(
        find.text('board: ${e.key}').first,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('board: ${e.key}'), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  test('every sample names an existing board', () {
    for (final s in designReviewSamples) {
      expect(
        File(
          'docs/superpowers/references/2026-11-05-glass-mockups/${s.board}.dc.html',
        ).existsSync(),
        isTrue,
        reason: s.board,
      );
    }
  });

  const realDir =
      '/home/shabin/projects/personal/borj/reference-captures/boards-2026-11-05';
  testWidgets('finds board images in a real reference directory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: GlassReviewScreen(referenceDir: realDir)),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Appearance section'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('board: PhoneSettings'), findsNothing);
    expect(File('$realDir/PhoneSettings.png').existsSync(), isTrue);
    expect(File('$realDir/PhoneSettingsDark.png').existsSync(), isTrue);
  }, skip: !Directory(realDir).existsSync());
}
