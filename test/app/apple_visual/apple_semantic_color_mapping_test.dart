import 'package:borj/app/apple_visual/foundation/apple_source_token_mapper.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:borj/app/apple_visual/foundation/apple_visual_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void expectSourceColor(
  AppleSourceColorToken token, {
  required String sourceId,
  required String sourceName,
  required double red,
  required double green,
  required double blue,
  required double alpha,
}) {
  expect(token.sourceId, sourceId);
  expect(token.sourceName, sourceName);
  expect(token.red, closeTo(red, 1e-12));
  expect(token.green, closeTo(green, 1e-12));
  expect(token.blue, closeTo(blue, 1e-12));
  expect(token.alpha, closeTo(alpha, 1e-12));
}

void main() {
  group('AppleSourceTokenMapper colors', () {
    test('maps iOS 27 light semantic colors to exact Sketch swatches', () {
      final colors = AppleSourceTokenMapper.colors(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
      );

      expect(colors.isResolved, isTrue);

      expectSourceColor(
        colors.primaryLabel,
        sourceId: '5941701F-DDE9-4318-ADDE-068451F0E822',
        sourceName: 'Labels/Light/1 Primary',
        red: 0,
        green: 0,
        blue: 0,
        alpha: 1,
      );
      expectSourceColor(
        colors.secondaryLabel,
        sourceId: 'CB3179CC-FD0F-4ED0-9C4D-324808246F3D',
        sourceName: 'Labels/Light/2 Secondary',
        red: 0.235294117647059,
        green: 0.235294117647059,
        blue: 0.262745098039216,
        alpha: 0.6,
      );
      expectSourceColor(
        colors.accentBlue,
        sourceId: '117CF35E-A575-4626-B899-FA9637445FFC',
        sourceName: 'System Colors/Light/8 Blue',
        red: 0,
        green: 0.533333333333333,
        blue: 1,
        alpha: 1,
      );
      expectSourceColor(
        colors.primaryFill,
        sourceId: 'FCBAD928-F1D7-4414-B032-65DA451F227A',
        sourceName: 'Fills/Light/1 Primary',
        red: 0.470588235294118,
        green: 0.470588235294118,
        blue: 0.470588235294118,
        alpha: 0.2,
      );
    });

    test('maps iOS 27 dark semantic colors to exact Sketch swatches', () {
      final colors = AppleSourceTokenMapper.colors(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.dark,
      );

      expect(colors.isResolved, isTrue);

      expectSourceColor(
        colors.primaryLabel,
        sourceId: '6BA01314-540A-41EB-96C6-38E13B190312',
        sourceName: 'Labels/Dark/1 Primary',
        red: 1,
        green: 1,
        blue: 1,
        alpha: 1,
      );
      expectSourceColor(
        colors.secondaryLabel,
        sourceId: '2037FC05-8030-45A5-9CC7-43E456560112',
        sourceName: 'Labels/Dark/2 Secondary',
        red: 0.92156862745098,
        green: 0.92156862745098,
        blue: 0.96078431372549,
        alpha: 0.6,
      );
      expectSourceColor(
        colors.accentBlue,
        sourceId: '0A6FA887-AE13-41DF-9AA5-07313DCA56DC',
        sourceName: 'System Colors/Dark/8 Blue',
        red: 0,
        green: 0.568627450980392,
        blue: 1,
        alpha: 1,
      );
      expectSourceColor(
        colors.primaryFill,
        sourceId: '66F6B232-E9AF-4A6B-A51E-BCB51BF9E518',
        sourceName: 'Fills/Dark/1 Primary',
        red: 0.470588235294118,
        green: 0.470588235294118,
        blue: 0.501960784313726,
        alpha: 0.36,
      );
    });

    test('maps macOS 27 light semantic colors to exact Sketch swatches', () {
      final colors = AppleSourceTokenMapper.colors(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.light,
      );

      expect(colors.isResolved, isTrue);

      expectSourceColor(
        colors.primaryLabel,
        sourceId: '2E2D2309-55DC-47E7-A385-800BA821048B',
        sourceName: 'Labels/Light/1 Primary',
        red: 0,
        green: 0,
        blue: 0,
        alpha: 0.85,
      );
      expectSourceColor(
        colors.secondaryLabel,
        sourceId: '4928019B-30D7-4558-B6B2-80F2E171E6EA',
        sourceName: 'Labels/Light/2 Secondary',
        red: 0,
        green: 0,
        blue: 0,
        alpha: 0.5,
      );
      expectSourceColor(
        colors.accentBlue,
        sourceId: '117CF35E-A575-4626-B899-FA9637445FFC',
        sourceName: 'System Colors/Light/8 Blue',
        red: 0,
        green: 0.533333333333333,
        blue: 1,
        alpha: 1,
      );
      expectSourceColor(
        colors.primaryFill,
        sourceId: '00E553B6-CE90-4F2A-9D4D-0FC52F66A894',
        sourceName: 'Fills/Light/1 Primary',
        red: 0,
        green: 0,
        blue: 0,
        alpha: 0.1,
      );
    });

    test('maps macOS 27 dark semantic colors to exact Sketch swatches', () {
      final colors = AppleSourceTokenMapper.colors(
        family: AppleVisualFamily.macos27,
        brightness: Brightness.dark,
      );

      expect(colors.isResolved, isTrue);

      expectSourceColor(
        colors.primaryLabel,
        sourceId: '5A246CA8-2E26-4ACF-A2AB-56D22F652B9E',
        sourceName: 'Labels/Dark/1 Primary',
        red: 1,
        green: 1,
        blue: 1,
        alpha: 1,
      );
      expectSourceColor(
        colors.secondaryLabel,
        sourceId: '332E3010-176D-4F98-BEE0-9839AD252637',
        sourceName: 'Labels/Dark/2 Secondary',
        red: 1,
        green: 1,
        blue: 1,
        alpha: 0.55,
      );
      expectSourceColor(
        colors.accentBlue,
        sourceId: '0A6FA887-AE13-41DF-9AA5-07313DCA56DC',
        sourceName: 'System Colors/Dark/8 Blue',
        red: 0,
        green: 0.568627450980392,
        blue: 1,
        alpha: 1,
      );
      expectSourceColor(
        colors.primaryFill,
        sourceId: 'B44716D1-A72A-4036-8D6D-60C60085A70D',
        sourceName: 'Fills/Dark/1 Primary',
        red: 1,
        green: 1,
        blue: 1,
        alpha: 0.1,
      );
    });
  });
}
