// test/app/theme/app_theme_test.dart
import 'package:borj/app/theme/app_theme.dart';
import 'package:borj/app/theme/original_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kit values', () {
    expect(AppTheme.light.colors.background, const Color(0xFFFFFFFF));
    expect(AppTheme.dark.colors.background, const Color(0xFF1B1C20));
    expect(AppTheme.dark.colors.window, const Color(0xFF24262B));
    expect(AppTheme.light.colors.accent, const Color(0xFF2F6FDB));
    expect(AppTheme.dark.colors.accent, const Color(0xFF5B93F0));
    expect(AppTheme.light.colors.text, const Color(0xFF1B2236));
  });

  test('type roles use Vazirmatn, no letter spacing, Persian line heights', () {
    final roles = AppTheme.light.text;
    for (final style in [
      roles.body,
      roles.callout,
      roles.subheadline,
      roles.footnote,
    ]) {
      expect(style.fontFamily, 'Vazirmatn');
      expect(style.letterSpacing, 0);
      expect(style.height, inInclusiveRange(1.5, 1.7));
    }
    expect(roles.largeTitle.fontSize, 34);
    expect(roles.body.fontSize, 15);
    expect(
      roles.tabular(roles.body).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('legacy themes carry AppTheme for their brightness', () {
    expect(OriginalTheme.light().extension<AppTheme>(), AppTheme.light);
    expect(OriginalTheme.dark().extension<AppTheme>(), AppTheme.dark);
  });

  testWidgets('of() falls back by brightness when no extension', (
    tester,
  ) async {
    late AppTheme resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            resolved = AppTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, AppTheme.dark);
  });

  test('lerp endpoints', () {
    expect(
      AppTheme.light.lerp(AppTheme.dark, 0).colors.text,
      AppTheme.light.colors.text,
    );
    expect(
      AppTheme.light.lerp(AppTheme.dark, 1).colors.text,
      AppTheme.dark.colors.text,
    );
  });

  test('Part B tokens', () {
    expect(AppTheme.light.colors.switchOn, const Color(0xFF1FB5A8));
    expect(AppTheme.dark.colors.switchOn, const Color(0xFF1FB5A8));
    expect(AppTheme.light.colors.switchOff, const Color(0x1F1B2236));
    expect(AppTheme.dark.colors.switchOff, const Color(0x29FFFFFF));
    expect(AppTheme.dark.colors.thumbSurface, const Color(0xFFFFFFFF));
    expect(AppTheme.dark.colors.thumbText, const Color(0xFF1F5FD0));
    expect(AppTheme.light.colors.pressShadow, const Color(0x33141E50));
    expect(AppTheme.light.colors.knobShadow, const Color(0x59141E50));
    expect(AppTheme.light.colors.scrim, const Color(0x400A0E1E));
    expect(AppTheme.dark.colors.scrim, const Color(0x73000000));
  });
}
