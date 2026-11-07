import 'package:borj/app/design/design.dart';
import 'package:borj/features/settings/application/appearance_preferences_controller.dart';
import 'package:borj/features/settings/data/in_memory_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:borj/features/settings/presentation/appearance_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

Future<InMemoryAppearancePreferencesStore> _pump(
  WidgetTester tester, {
  Brightness b = Brightness.light,
  double scale = 1,
}) async {
  final store = InMemoryAppearancePreferencesStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appearancePreferencesStoreProvider.overrideWithValue(store)],
      child: glassTestApp(
        const SizedBox(
          width: 390,
          child: SingleChildScrollView(child: AppearanceSection()),
        ),
        brightness: b,
        textScale: scale,
      ),
    ),
  );
  return store;
}

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders the board section (${v.name})', (tester) async {
      await _pump(tester, b: v.brightness, scale: v.textScale);
      expect(tester.takeException(), isNull);
      for (final t in [
        'ظاهر',
        'روشن',
        'تیره',
        'خودکار',
        'شدت شیشه',
        '۵۰٪',
        'کاهش حرکت',
        'کاهش شفافیت',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });
  }

  testWidgets('one panel glass; everything inside is flat', (tester) async {
    await _pump(tester);
    expect(find.byType(AppGlass), findsOneWidget);
  });

  testWidgets('mode segment and switches write preferences', (tester) async {
    final store = await _pump(tester);
    await tester.tap(find.text('تیره'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GlassToggle).first);
    await tester.tap(find.byType(GlassToggle).last);
    await tester.pumpAndSettle();
    final saved = await store.load();
    expect(saved.mode, AppearanceMode.dark);
    expect(saved.reduceMotion, isTrue);
    expect(saved.reduceTransparency, isTrue);
  });

  testWidgets('slider previews while dragging and saves on release', (
    tester,
  ) async {
    final store = await _pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppearanceSection)),
    );
    final slider = find.byType(Slider);
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(-60, 0)); // RTL: left increases
    await tester.pump();
    final previewed = container
        .read(appearancePreferencesProvider)
        .glassIntensity;
    expect(previewed, isNot(0.5));
    expect(previewed, greaterThan(0.5), reason: 'RTL leftward increases');
    expect(previewed, greaterThan(0.5), reason: "RTL leftward increases");
    expect(
      (await store.load()).glassIntensity,
      0.5,
      reason: 'no save while dragging',
    );
    await gesture.up();
    await tester.pump();
    expect((await store.load()).glassIntensity, previewed);
  });

  testWidgets('semantics increase commits', (tester) async {
    final handle = tester.ensureSemantics();
    final store = await _pump(tester);
    tester.semantics.performAction(
      find.semantics.byAction(SemanticsAction.increase),
      SemanticsAction.increase,
    );
    await tester.pump();
    expect((await store.load()).glassIntensity, greaterThan(0.5));
    handle.dispose();
  });
}
