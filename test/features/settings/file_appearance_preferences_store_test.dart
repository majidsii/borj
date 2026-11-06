import 'dart:io';

import 'package:borj/features/settings/data/file_appearance_preferences_store.dart';
import 'package:borj/features/settings/domain/appearance_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late FileAppearancePreferencesStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('borj_prefs_');
    store = FileAppearancePreferencesStore(directory: () async => dir);
  });
  tearDown(() => dir.delete(recursive: true));

  File file(String name) => File('${dir.path}/$name');

  test('missing file loads defaults', () async {
    expect(await store.load(), AppearancePreferences.defaults);
  });

  test('save then load round-trips and leaves no temp file', () async {
    const p = AppearancePreferences(
      mode: AppearanceMode.dark,
      glassIntensity: 0.8,
    );
    await store.save(p);
    expect(await store.load(), p);
    expect(file('borj-preferences.json.tmp').existsSync(), isFalse);
  });

  test('a second save replaces the first', () async {
    await store.save(const AppearancePreferences(mode: AppearanceMode.dark));
    await store.save(const AppearancePreferences(mode: AppearanceMode.light));
    expect((await store.load()).mode, AppearanceMode.light);
  });

  test('corrupt file is moved aside and defaults load', () async {
    file('borj-preferences.json').writeAsStringSync('{not json');
    expect(await store.load(), AppearancePreferences.defaults);
    expect(file('borj-preferences.json').existsSync(), isFalse);
    expect(
      file('borj-preferences.json.corrupt').readAsStringSync(),
      '{not json',
    );
  });
}
