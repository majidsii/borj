import 'package:borj/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple typography source mapping', () {
    test('ios body maps to exact extracted source record', () {
      final token = AppleSourceTokenMapper.typographyRole(
        family: AppleVisualFamily.ios27,
        role: AppleTypographyRole.body,
      );

      expect(token.sourceId, '9F810419-DCD9-437A-9860-34B67E9FB8EA');
      expect(token.sourceName, '06 Body/Default');
      expect(token.fontSize, closeTo(17.0, 1e-12));
      expect(token.lineHeight, isNull);
      expect(token.sourcePostScriptName, null);
      expect(token.sourceWeight, isNull);
    });

    test('ios headline maps to exact extracted source record', () {
      final token = AppleSourceTokenMapper.typographyRole(
        family: AppleVisualFamily.ios27,
        role: AppleTypographyRole.headline,
      );

      expect(token.sourceId, 'BE6E4256-5EB9-49BD-9221-98C3E76F6E65');
      expect(token.sourceName, '05 Headline/1 Default');
      expect(token.fontSize, closeTo(17.0, 1e-12));
      expect(token.lineHeight, isNull);
      expect(token.sourcePostScriptName, null);
      expect(token.sourceWeight, isNull);
    });

    test('ios title1 maps to exact extracted source record', () {
      final token = AppleSourceTokenMapper.typographyRole(
        family: AppleVisualFamily.ios27,
        role: AppleTypographyRole.title1,
      );

      expect(token.sourceId, '240E079F-3BDE-4AA5-B0EE-F43ECA158292');
      expect(token.sourceName, '02 Title1/1 Default');
      expect(token.fontSize, closeTo(28.0, 1e-12));
      expect(token.lineHeight, isNull);
      expect(token.sourcePostScriptName, null);
      expect(token.sourceWeight, isNull);
    });

    test('macos body maps to exact extracted source record', () {
      final token = AppleSourceTokenMapper.typographyRole(
        family: AppleVisualFamily.macos27,
        role: AppleTypographyRole.body,
      );

      expect(token.sourceId, 'F42272DC-4A56-4A59-994A-6D990EC84C58');
      expect(token.sourceName, '06 Body/Default');
      expect(token.fontSize, closeTo(13.0, 1e-12));
      expect(token.lineHeight, isNull);
      expect(token.sourcePostScriptName, null);
      expect(token.sourceWeight, isNull);
    });

    test('macos headline maps to exact extracted source record', () {
      final token = AppleSourceTokenMapper.typographyRole(
        family: AppleVisualFamily.macos27,
        role: AppleTypographyRole.headline,
      );

      expect(token.sourceId, '06055D2A-84CA-45CE-9F29-56E9279CF7B6');
      expect(token.sourceName, '05 Headline/Default');
      expect(token.fontSize, closeTo(13.0, 1e-12));
      expect(token.lineHeight, isNull);
      expect(token.sourcePostScriptName, null);
      expect(token.sourceWeight, isNull);
    });

    test('macos title1 maps to exact extracted source record', () {
      final token = AppleSourceTokenMapper.typographyRole(
        family: AppleVisualFamily.macos27,
        role: AppleTypographyRole.title1,
      );

      expect(token.sourceId, 'BF7ECE3E-DA6A-4F3E-B367-86D880A9EBF4');
      expect(token.sourceName, '02 Title1/Default');
      expect(token.fontSize, closeTo(22.0, 1e-12));
      expect(token.lineHeight, isNull);
      expect(token.sourcePostScriptName, null);
      expect(token.sourceWeight, isNull);
    });

    test('uses approved Vazirmatn deviation on non-Apple Persian runtime', () {
      expect(AppleTypographyRuntime.nonApplePersianFontFamily, 'Vazirmatn');
    });

    test('does not describe non-Apple glyph artwork as source-exact', () {
      expect(AppleTypographyRuntime.nonAppleGlyphArtworkIsExact, isFalse);
    });
  });

  // B5_TYPOGRAPHY_GROUP_RESOLUTION_RED
  group('Apple typography token group resolution', () {
    for (final family in AppleVisualFamily.values) {
      test(
        '$family resolves all approved typography roles as one token group',
        () {
          final typography = AppleSourceTokenMapper.typography(family: family);

          expect(typography.isResolved, isTrue);
          expect(
            typography.body.sourceId,
            AppleSourceTokenMapper.typographyRole(
              family: family,
              role: AppleTypographyRole.body,
            ).sourceId,
          );
          expect(
            typography.headline.sourceId,
            AppleSourceTokenMapper.typographyRole(
              family: family,
              role: AppleTypographyRole.headline,
            ).sourceId,
          );
          expect(
            typography.title1.sourceId,
            AppleSourceTokenMapper.typographyRole(
              family: family,
              role: AppleTypographyRole.title1,
            ).sourceId,
          );
        },
      );
    }

    test('unresolved typography group never exposes guessed role values', () {
      expect(AppleTypographyTokens.empty.isResolved, isFalse);
      expect(() => AppleTypographyTokens.empty.body, throwsStateError);
      expect(() => AppleTypographyTokens.empty.headline, throwsStateError);
      expect(() => AppleTypographyTokens.empty.title1, throwsStateError);
    });
  });
}
