import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/features/today/presentation/today_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

final _now = DateTime(2026, 11, 4, 14, 30);

Widget _header(
  Size window, {
  VoidCallback? onLong,
  Brightness b = Brightness.light,
  double s = 1.0,
}) => glassTestApp(
  brightness: b,
  textScale: s,
  MediaQuery(
    data: MediaQueryData(size: window),
    child: SizedBox(
      width: window.width,
      child: TodayHeader(now: _now, onTitleLongPress: onLong),
    ),
  ),
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final v in glassTestVariants) {
    for (final w in [const Size(390, 844), const Size(1440, 900)]) {
      testWidgets('renders ${w.width} (${v.name})', (tester) async {
        await tester.pumpWidget(_header(w, b: v.brightness, s: v.textScale));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('compact: large title with the short date, no glass', (
    tester,
  ) async {
    await tester.pumpWidget(_header(const Size(390, 844)));
    expect(find.text('امروز'), findsOneWidget);
    expect(find.text('چهارشنبه ۱۳ آبان'), findsOneWidget);
    expect(find.byType(AppGlass), findsNothing);
  });

  testWidgets('expanded: clear-glass date chip with both date lines', (
    tester,
  ) async {
    await tester.pumpWidget(_header(const Size(1440, 900)));
    expect(find.byKey(const ValueKey('today-date-chip')), findsOneWidget);
    expect(find.text('چهارشنبه، ۴ نوامبر'), findsOneWidget);
    expect(find.text('۱۳ آبان ۱۴۰۵'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is AppGlass && w.role == GlassRole.clear),
      findsOneWidget,
    );
    expect(GlassLayerKind.clear.allows(GlassRole.clear), isTrue);
  });

  for (final w in [const Size(390, 844), const Size(1440, 900)]) {
    testWidgets('long-press the title (${w.width})', (tester) async {
      var pressed = false;
      await tester.pumpWidget(_header(w, onLong: () => pressed = true));
      final title = find.byKey(const ValueKey('today-title'));
      await tester.longPress(
        w.width < 600
            ? find.descendant(of: title, matching: find.text('امروز'))
            : title,
      );
      expect(pressed, isTrue);
    });
  }

  // A3 / plan Decision 6: GlassRole.clear is near-transparent (no fallback
  // fill), so the chip text follows the theme over the page background.
  // Light page = AppColors.background (white); dark page = the lightest dark
  // base, backdropTop, which is the worst case for light text.
  for (final dark in [false, true]) {
    testWidgets('chip text is >= 4.5:1 (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      await tester.pumpWidget(
        _header(
          const Size(1440, 900),
          b: dark ? Brightness.dark : Brightness.light,
        ),
      );
      final theme = dark ? AppTheme.dark : AppTheme.light;
      final bg = dark ? theme.colors.backdropTop : theme.colors.background;
      for (final text in ['چهارشنبه، ۴ نوامبر', '۱۳ آبان ۱۴۰۵']) {
        final color = tester.widget<Text>(find.text(text)).style!.color!;
        expect(color, isNot(AppTextTone.onTint.resolve(theme.colors)));
        expect(_contrast(color, bg), greaterThanOrEqualTo(4.5), reason: text);
      }
    });
  }

  test('onTint (white) would fail on the light clear chip', () {
    expect(
      _contrast(
        AppTextTone.onTint.resolve(AppTheme.light.colors),
        AppTheme.light.colors.background,
      ),
      lessThan(4.5),
    );
  });
}
