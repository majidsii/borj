import 'package:borj/app/design/design.dart';
import 'package:borj/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/glass_test_app.dart';

void main() {
  for (final v in glassTestVariants) {
    testWidgets('renders every role without errors (${v.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        glassTestApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in AppTextRole.values)
                AppText('سلام ۱۲۳', role: role, tabular: true),
            ],
          ),
          brightness: v.brightness,
          textScale: v.textScale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('سلام ۱۲۳'), findsNWidgets(AppTextRole.values.length));
    });
  }

  testWidgets('role and tone resolve from AppTheme', (tester) async {
    await tester.pumpWidget(
      glassTestApp(
        const AppText(
          'سلام',
          role: AppTextRole.headline,
          tone: AppTextTone.secondary,
        ),
        brightness: Brightness.dark,
      ),
    );
    final text = tester.widget<Text>(find.text('سلام'));
    expect(text.style!.fontSize, AppTheme.dark.text.headline.fontSize);
    expect(text.style!.color, AppTheme.dark.colors.textSecondary);
  });

  testWidgets('tabular digits', (tester) async {
    await tester.pumpWidget(glassTestApp(const AppText('۱۲۳', tabular: true)));
    expect(
      tester.widget<Text>(find.text('۱۲۳')).style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('directional const icon flips in RTL, AppIcon adds no Transform', (
    tester,
  ) async {
    await tester.pumpWidget(glassTestApp(const AppIcon(Icons.chevron_left)));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon!.matchTextDirection, isTrue);
    // Flutter's own Icon mirrors matchTextDirection glyphs with a Transform
    // inside itself (icon.dart). AppIcon adds none of its own: every Transform
    // below AppIcon is also below the Icon.
    expect(
      find.descendant(
        of: find.byType(AppIcon),
        matching: find.byType(Transform),
      ),
      findsNWidgets(
        find
            .descendant(of: find.byType(Icon), matching: find.byType(Transform))
            .evaluate()
            .length,
      ),
    );
  });

  testWidgets('decoration is applied to the resolved style', (tester) async {
    await tester.pumpWidget(
      glassTestApp(const AppText('x', decoration: TextDecoration.lineThrough)),
    );
    expect(
      tester.widget<Text>(find.text('x')).style!.decoration,
      TextDecoration.lineThrough,
    );
  });

  test('inverse resolves to the background colour in both themes', () {
    for (final t in [AppTheme.light, AppTheme.dark]) {
      expect(AppTextTone.inverse.resolve(t.colors), t.colors.background);
    }
  });
}
