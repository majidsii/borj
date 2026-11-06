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

  test('valid JSON that is not a map is treated as corrupt', () async {
    file('borj-preferences.json').writeAsStringSync('[]');
    expect(await store.load(), AppearancePreferences.defaults);
    expect(file('borj-preferences.json').existsSync(), isFalse);
    expect(file('borj-preferences.json.corrupt').readAsStringSync(), '[]');
  });

  test('a failing corrupt-file rename still loads defaults', () async {
    file('borj-preferences.json').writeAsStringSync('{not json');
    Directory('${dir.path}/borj-preferences.json.corrupt').createSync();
    file('borj-preferences.json.corrupt/x').writeAsStringSync('x');
    expect(await store.load(), AppearancePreferences.defaults);
  });

  test('a throwing directory callback loads defaults', () async {
    final broken = FileAppearancePreferencesStore(
      directory: () async => throw StateError('no documents dir'),
    );
    expect(await broken.load(), AppearancePreferences.defaults);
  });

  test('concurrent saves are serialized and the last one wins', () async {
    final first = store.save(const AppearancePreferences(glassIntensity: 0.1));
    final second = store.save(const AppearancePreferences(glassIntensity: 0.9));
    await Future.wait([first, second]);
    expect((await store.load()).glassIntensity, 0.9);
    expect(file('borj-preferences.json.tmp').existsSync(), isFalse);
  });
}
