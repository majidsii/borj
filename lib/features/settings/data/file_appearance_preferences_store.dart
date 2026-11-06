import 'dart:convert';
import 'dart:io';

import '../domain/appearance_preferences.dart';

/// Stores appearance preferences as JSON beside `borj.sqlite`.
///
/// Writes go to a temp file that is renamed over the target, so a crash never
/// leaves a half-written file. Unreadable content is moved to `.corrupt` and
/// defaults are used.
final class FileAppearancePreferencesStore
    implements AppearancePreferencesStore {
  const FileAppearancePreferencesStore({required this.directory});

  static const String fileName = 'borj-preferences.json';

  final Future<Directory> Function() directory;

  Future<File> _file() async => File('${(await directory()).path}/$fileName');

  @override
  Future<AppearancePreferences> load() async {
    final file = await _file();
    if (!file.existsSync()) {
      return AppearancePreferences.defaults;
    }
    try {
      return AppearancePreferences.fromJson(
        jsonDecode(await file.readAsString()),
      );
    } on FormatException {
      await file.rename('${file.path}.corrupt');
      return AppearancePreferences.defaults;
    } on FileSystemException {
      return AppearancePreferences.defaults;
    }
  }

  @override
  Future<void> save(AppearancePreferences value) async {
    final file = await _file();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(value.toJson()), flush: true);
    await temp.rename(file.path);
  }
}
