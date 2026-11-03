import 'dart:io';

/// Finds v1's `data.json` on desktop. Android is manual-import only (v2 may
/// not be able to read v1's private files). The file is only ever read.
final class LegacyV1SourceLocator {
  const LegacyV1SourceLocator({this.operatingSystem, this.environment});

  static const String appDirectoryName = 'dashboard-shakhsi';
  static const String fileName = 'data.json';

  final String? operatingSystem;
  final Map<String, String>? environment;

  String? candidatePath() {
    final os = operatingSystem ?? Platform.operatingSystem;
    final env = environment ?? Platform.environment;
    final home = _nonEmpty(env['HOME']) ?? _nonEmpty(env['USERPROFILE']);

    switch (os) {
      case 'linux':
        final xdg = _nonEmpty(env['XDG_DATA_HOME']);
        final root = xdg ?? (home == null ? null : '$home/.local/share');
        return root == null ? null : '$root/$appDirectoryName/$fileName';
      case 'macos':
        return home == null
            ? null
            : '$home/Library/Application Support/$appDirectoryName/$fileName';
      case 'windows':
        final root = _nonEmpty(env['APPDATA']) ?? home;
        return root == null ? null : '$root\\$appDirectoryName\\$fileName';
      default:
        return null;
    }
  }

  Future<File?> detect() async {
    final path = candidatePath();
    if (path == null) return null;
    try {
      final file = File(path);
      return await file.exists() ? file : null;
    } on FileSystemException {
      return null;
    }
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;
}
