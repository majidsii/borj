import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('windows icon is the brand ico', () {
    expect(
      File('windows/runner/resources/app_icon.ico').readAsBytesSync(),
      File('assets/brand/png/borj.ico').readAsBytesSync(),
    );
  });

  test('macOS app icons are the brand PNGs', () {
    for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
      expect(
        File(
          'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$s.png',
        ).readAsBytesSync(),
        File('assets/brand/png/borj-app-icon-$s.png').readAsBytesSync(),
        reason: '$s',
      );
    }
  });

  test('android launcher icons are PNGs of the expected width', () {
    const widths = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    widths.forEach((density, width) {
      final file = File(
        'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      );
      expect(file.existsSync(), isTrue, reason: density);
      final bytes = file.readAsBytesSync();
      expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: density);
      final w = ByteData.sublistView(bytes, 16, 20).getUint32(0);
      expect(w, width, reason: density);
    });
  });

  test('linux runner sets the window icon', () {
    expect(
      File('linux/runner/my_application.cc').readAsStringSync(),
      contains('gtk_window_set_icon_from_file'),
    );
  });
}
