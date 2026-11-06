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
  FileAppearancePreferencesStore({required this.directory});

  static const String fileName = 'borj-preferences.json';

  final Future<Directory> Function() directory;

  Future<void> _lastSave = Future<void>.value();

  Future<File> _file() async => File('${(await directory()).path}/$fileName');

  /// Never throws: preferences must not block launch.
  @override
  Future<AppearancePreferences> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) {
        return AppearancePreferences.defaults;
      }
      final String text;
      try {
        text = await file.readAsString();
      } on FileSystemException {
        return AppearancePreferences.defaults;
      }
      Object? decoded;
      var corrupt = false;
      try {
        decoded = jsonDecode(text);
        corrupt = decoded is! Map<String, Object?>;
      } on FormatException {
        corrupt = true;
      }
      if (corrupt) {
        try {
          await file.rename('${file.path}.corrupt');
        } on Object {
          // Keep going with defaults even if the file cannot be moved aside.
        }
        return AppearancePreferences.defaults;
      }
      return AppearancePreferences.fromJson(decoded);
    } on Object {
      return AppearancePreferences.defaults;
    }
  }

  /// Saves are serialized so concurrent calls never share the temp file.
  @override
  Future<void> save(AppearancePreferences value) {
    final previous = _lastSave;
    final next = () async {
      try {
        await previous;
      } on Object {
        // A failed earlier save does not block this one.
      }
      await _write(value);
    }();
    _lastSave = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _write(AppearancePreferences value) async {
    final file = await _file();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(value.toJson()), flush: true);
    await temp.rename(file.path);
  }
}
