import 'package:borj/app/apple_visual/generated/apple_source_reference.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generated Apple source reference', () {
    test('is pinned to the frozen Apple source hashes', () {
      expect(
        AppleSourceReference.iosSha256,
        '5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295',
      );
      expect(
        AppleSourceReference.macosSha256,
        '8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28',
      );
    });

    test('preserves the frozen source page counts', () {
      expect(AppleSourceReference.iosPageCount, 34);
      expect(AppleSourceReference.macosPageCount, 37);
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
