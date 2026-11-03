import 'dart:io';

import 'package:dashboard_shakhsi/features/legacy_import/data/legacy_v1_source_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('linux honors XDG_DATA_HOME first, then ~/.local/share', () {
    const withXdg = LegacyV1SourceLocator(
      operatingSystem: 'linux',
      environment: <String, String>{
        'XDG_DATA_HOME': '/data/xdg',
        'HOME': '/home/u',
      },
    );
    const withoutXdg = LegacyV1SourceLocator(
      operatingSystem: 'linux',
      environment: <String, String>{'HOME': '/home/u'},
    );

    expect(withXdg.candidatePath(), '/data/xdg/dashboard-shakhsi/data.json');
    expect(
      withoutXdg.candidatePath(),
      '/home/u/.local/share/dashboard-shakhsi/data.json',
    );
  });

  test('windows uses APPDATA, falling back to the home directory', () {
    const withAppData = LegacyV1SourceLocator(
      operatingSystem: 'windows',
      environment: <String, String>{
        'APPDATA': r'C:\Users\u\AppData\Roaming',
        'USERPROFILE': r'C:\Users\u',
      },
    );
    const homeOnly = LegacyV1SourceLocator(
      operatingSystem: 'windows',
      environment: <String, String>{'USERPROFILE': r'C:\Users\u'},
    );

    expect(
      withAppData.candidatePath(),
      r'C:\Users\u\AppData\Roaming\dashboard-shakhsi\data.json',
    );
    expect(homeOnly.candidatePath(), r'C:\Users\u\dashboard-shakhsi\data.json');
  });

  test('macos uses Library/Application Support', () {
    const locator = LegacyV1SourceLocator(
      operatingSystem: 'macos',
      environment: <String, String>{'HOME': '/Users/u'},
    );

    expect(
      locator.candidatePath(),
      '/Users/u/Library/Application Support/dashboard-shakhsi/data.json',
    );
  });

  test('android and unknown platforms have no auto-detect path', () {
    const android = LegacyV1SourceLocator(
      operatingSystem: 'android',
      environment: <String, String>{'HOME': '/data'},
    );
    const noHome = LegacyV1SourceLocator(
      operatingSystem: 'linux',
      environment: <String, String>{},
    );

    expect(android.candidatePath(), isNull);
    expect(noHome.candidatePath(), isNull);
  });

  test('detect returns the file only when it exists', () async {
    final directory = await Directory.systemTemp.createTemp('v1-locator-');
    try {
      final locator = LegacyV1SourceLocator(
        operatingSystem: 'linux',
        environment: <String, String>{'XDG_DATA_HOME': directory.path},
      );
      expect(await locator.detect(), isNull);

      final file = File('${directory.path}/dashboard-shakhsi/data.json');
      await file.create(recursive: true);
      await file.writeAsString('{}');

      final detected = await locator.detect();
      expect(detected?.path, file.path);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
