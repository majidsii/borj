import 'dart:io';

const String _legacyBaseName = 'dashboard_shakhsi.sqlite';
const String _currentBaseName = 'borj.sqlite';
const List<String> _suffixes = <String>['', '-wal', '-shm', '-journal'];

/// Renames the pre-Borj database files in [directory] to their Borj names.
///
/// Moves `dashboard_shakhsi.sqlite` and its existing `-wal`, `-shm` and
/// `-journal` siblings to `borj.sqlite*`, but only when `borj.sqlite` does not
/// exist yet. Nothing is ever deleted or overwritten.
void moveLegacyDatabaseFiles(Directory directory) {
  final target = File('${directory.path}/$_currentBaseName');
  if (target.existsSync()) {
    return;
  }
  final legacy = File('${directory.path}/$_legacyBaseName');
  if (!legacy.existsSync()) {
    return;
  }
  for (final suffix in _suffixes) {
    final source = File('${directory.path}/$_legacyBaseName$suffix');
    if (source.existsSync()) {
      source.renameSync('${directory.path}/$_currentBaseName$suffix');
    }
  }
}
