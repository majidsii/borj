import 'package:borj/app/apple_visual/generated/apple_source_reference.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generated Apple source reference', () {
    test('is pinned to the frozen Apple source hashes', () {
      expect(
        AppleSourceReference.iosSha256,
        '839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171',
      );
      expect(
        AppleSourceReference.macosSha256,
        'f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d',
      );
    });

    test('preserves the frozen source page counts', () {
      expect(AppleSourceReference.iosPageCount, 36);
      expect(AppleSourceReference.macosPageCount, 38);
    });

    test('exposes source-owned token records instead of guessed values', () {
      expect(AppleSourceReference.iosSwatches, isNotEmpty);
      expect(AppleSourceReference.macosSwatches, isNotEmpty);
      expect(AppleSourceReference.iosTextStyles, isNotEmpty);
      expect(AppleSourceReference.macosTextStyles, isNotEmpty);
      expect(AppleSourceReference.iosLayerStyles, isNotEmpty);
      expect(AppleSourceReference.macosLayerStyles, isNotEmpty);

      expect(
        AppleSourceReference.iosSwatches.every(
          (entry) => entry.sourceId.isNotEmpty && entry.name.isNotEmpty,
        ),
        isTrue,
      );
      expect(
        AppleSourceReference.macosLayerStyles.every(
          (entry) => entry.sourceId.isNotEmpty && entry.name.isNotEmpty,
        ),
        isTrue,
      );
    });

    test('keeps Liquid Glass source styles discoverable by source name', () {
      expect(
        AppleSourceReference.iosLayerStyles.any(
          (entry) => entry.name.toLowerCase().contains('liquid glass'),
        ),
        isTrue,
      );
      expect(
        AppleSourceReference.macosLayerStyles.any(
          (entry) => entry.name.toLowerCase().contains('liquid glass'),
        ),
        isTrue,
      );
    });
  });
}
