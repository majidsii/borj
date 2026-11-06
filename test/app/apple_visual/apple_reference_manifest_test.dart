import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const iosSha =
      '839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171';
  const macosSha =
      'f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d';
  const macosAssetsSha =
      '4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31';

  File generatedReference() =>
      File('docs/superpowers/references/generated/apple_ui_kit_reference.json');

  test('generated Apple reference is pinned to the frozen source hashes', () {
    final file = generatedReference();

    expect(
      file.existsSync(),
      isTrue,
      reason:
          'RED_EXPECTED: Gate A extractor has not generated the reference JSON yet.',
    );

    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final ios = data['ios'] as Map<String, dynamic>;
    final macos = data['macos'] as Map<String, dynamic>;
    final assets = data['macosAssets'] as Map<String, dynamic>;

    expect((ios['source'] as Map<String, dynamic>)['sha256'], iosSha);
    expect((macos['source'] as Map<String, dynamic>)['sha256'], macosSha);
    expect(
      (assets['source'] as Map<String, dynamic>)['sha256'],
      macosAssetsSha,
    );
  });

  test('generated reference contains the locked page counts', () {
    final file = generatedReference();

    expect(
      file.existsSync(),
      isTrue,
      reason:
          'RED_EXPECTED: Gate A extractor has not generated the reference JSON yet.',
    );

    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final ios = data['ios'] as Map<String, dynamic>;
    final macos = data['macos'] as Map<String, dynamic>;

    expect(ios['pageCount'], 36);
    expect(macos['pageCount'], 38);
  });
}
