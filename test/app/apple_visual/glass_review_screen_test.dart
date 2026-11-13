import 'dart:io';

import 'package:borj/app/apple_visual/review/design_review_samples.dart';
import 'package:borj/app/apple_visual/review/glass_review_screen.dart';
import 'package:borj/app/design/design.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // The list builds lazily and the notice sits below every design sample.
    await tester.scrollUntilVisible(
      find.text('No reference images'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
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
      // The ListView builds lazily, so check the board text inside this
      // sample's own card (the nearest Column above its label).
      final card = find
          .ancestor(of: find.text(sample.label), matching: find.byType(Column))
          .first;
      expect(
        find.descendant(
          of: card,
          matching: find.text('board: ${sample.board}'),
        ),
        findsNWidgets(1),
        reason: sample.label,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone Today samples keep the phone layout in a wide window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: GlassReviewScreen(referenceDir: null)),
    );
    await tester.pump();
    Finder cardOf(String label) => find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first;
    for (final (label, grouped) in const [
      ('TodayTasksCard large', false),
      ('TodayTasksCard expanded grouping', true),
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(of: cardOf(label), matching: find.text('صبح')),
        grouped ? findsWidgets : findsNothing,
        reason: label,
      );
    }
  });

  testWidgets('the swiped TaskGlassRow sample shows its actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: GlassReviewScreen(referenceDir: null)),
    );
    await tester.scrollUntilVisible(
      find.text('TaskGlassRow normal, done, swiped open'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final card = find
        .ancestor(
          of: find.text('TaskGlassRow normal, done, swiped open'),
          matching: find.byType(Column),
        )
        .first;
    expect(
      find.descendant(of: card, matching: find.text('حذف').hitTestable()),
      findsWidgets,
    );
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

  testWidgets('appearance sample never touches the app preferences', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final spy = _SpyStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appearancePreferencesStoreProvider.overrideWithValue(spy)],
        child: const MaterialApp(home: GlassReviewScreen(referenceDir: null)),
      ),
    );
    await tester.pump();
    final root = ProviderScope.containerOf(
      tester.element(find.byType(GlassReviewScreen)),
    );
    final before = root.read(appearancePreferencesProvider);
    await tester.scrollUntilVisible(
      find.text('Appearance section'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    // Dark and light sides each hold one section; drive both.
    for (final text in <String>['تیره', 'کاهش حرکت']) {
      for (final f in find.text(text).evaluate().toList()) {
        await tester.ensureVisible(find.byWidget(f.widget).first);
        await tester.tap(find.byWidget(f.widget).first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    // Toggles are not text-labelled targets; tap every switch as well.
    for (final t in find.byType(GlassToggle).evaluate().toList()) {
      await tester.tap(find.byWidget(t.widget).first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(root.read(appearancePreferencesProvider), before);
    expect(spy.saves, isEmpty);
    expect(await spy.load(), AppearancePreferences.defaults);
  });

  final boardsDir = Platform.environment['BORJ_BOARDS_DIR'];
  final boardsAvailable =
      boardsDir != null && Directory(boardsDir).existsSync();
  testWidgets('finds board images in a real reference directory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: GlassReviewScreen(referenceDir: boardsDir)),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Appearance section'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('board: PhoneSettings'), findsNothing);
    expect(find.byType(Image), findsWidgets);
    expect(File('$boardsDir/PhoneSettings.png').existsSync(), isTrue);
    expect(File('$boardsDir/PhoneSettingsDark.png').existsSync(), isTrue);
  }, skip: !boardsAvailable);
}

final class _SpyStore implements AppearancePreferencesStore {
  final List<AppearancePreferences> saves = [];

  @override
  Future<AppearancePreferences> load() async => AppearancePreferences.defaults;

  @override
  Future<void> save(AppearancePreferences value) async => saves.add(value);
}
