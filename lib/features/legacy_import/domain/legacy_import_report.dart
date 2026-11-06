import 'package:borj/features/legacy_import/domain/legacy_snapshot.dart';

final class LegacyImportPreview {
  const LegacyImportPreview({
    required this.toImport,
    required this.alreadyImported,
    required this.skipped,
    required this.warnings,
  });

  final Map<LegacyEntityType, int> toImport;
  final Map<LegacyEntityType, int> alreadyImported;
  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  int get totalToImport => toImport.values.fold(0, (sum, n) => sum + n);
}

final class LegacyImportReport {
  const LegacyImportReport({
    required this.imported,
    required this.alreadyImported,
    required this.skipped,
    required this.warnings,
  });

  final Map<LegacyEntityType, int> imported;
  final Map<LegacyEntityType, int> alreadyImported;
  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  int get totalImported => imported.values.fold(0, (sum, n) => sum + n);
}
