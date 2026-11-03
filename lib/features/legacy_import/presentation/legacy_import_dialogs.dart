import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_import_report.dart';
import 'package:dashboard_shakhsi/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:dashboard_shakhsi/features/legacy_import/presentation/legacy_import_labels.dart';
import 'package:flutter/material.dart';

final class LegacyImportPreviewDialog extends StatelessWidget {
  const LegacyImportPreviewDialog({required this.preview, super.key});

  final LegacyImportPreview preview;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('پیش‌نمایش ورود اطلاعات'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final type in LegacyEntityType.values)
                _CountRow(
                  keyPrefix: 'legacy-count',
                  type: type,
                  count: preview.toImport[type] ?? 0,
                  already: preview.alreadyImported[type] ?? 0,
                ),
              if (preview.totalToImport == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'چیز جدیدی برای ورود وجود ندارد.',
                    key: ValueKey<String>('legacy-nothing-new'),
                  ),
                ),
              _IssueList(skipped: preview.skipped, warnings: preview.warnings),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('legacy-import-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('انصراف'),
        ),
        if (preview.totalToImport > 0)
          FilledButton(
            key: const ValueKey<String>('legacy-import-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ورود اطلاعات'),
          ),
      ],
    );
  }
}

final class LegacyImportReportDialog extends StatelessWidget {
  const LegacyImportReportDialog({required this.report, super.key});

  final LegacyImportReport report;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('نتیجه ورود اطلاعات'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final type in LegacyEntityType.values)
                _CountRow(
                  keyPrefix: 'legacy-report-count',
                  type: type,
                  count: report.imported[type] ?? 0,
                  already: report.alreadyImported[type] ?? 0,
                ),
              _IssueList(skipped: report.skipped, warnings: report.warnings),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          key: const ValueKey<String>('legacy-import-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('بستن'),
        ),
      ],
    );
  }
}

final class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.keyPrefix,
    required this.type,
    required this.count,
    required this.already,
  });

  final String keyPrefix;
  final LegacyEntityType type;
  final int count;
  final int already;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(legacyEntityLabel(type))),
          Text(
            legacyDigits(count),
            key: ValueKey<String>('$keyPrefix-${type.name}'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (already > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Text(
                '(${legacyDigits(already)} قبلاً وارد شده)',
                key: ValueKey<String>('$keyPrefix-already-${type.name}'),
              ),
            ),
        ],
      ),
    );
  }
}

final class _IssueList extends StatelessWidget {
  const _IssueList({required this.skipped, required this.warnings});

  final List<LegacySkippedRow> skipped;
  final List<LegacyWarning> warnings;

  @override
  Widget build(BuildContext context) {
    if (skipped.isEmpty && warnings.isEmpty) return const SizedBox.shrink();

    final skippedCounts = <(LegacyEntityType, LegacySkipReason), int>{};
    for (final row in skipped) {
      final key = (row.entityType, row.reason);
      skippedCounts[key] = (skippedCounts[key] ?? 0) + 1;
    }
    final warningCounts = <LegacyWarningCode, int>{};
    for (final warning in warnings) {
      warningCounts[warning.code] = (warningCounts[warning.code] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        key: const ValueKey<String>('legacy-issues'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'ردیف‌های ردشده و هشدارها',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          for (final entry in skippedCounts.entries)
            Text(
              '${legacyEntityLabel(entry.key.$1)}: '
              '${legacySkipReasonLabel(entry.key.$2)} '
              '(${legacyDigits(entry.value)})',
            ),
          for (final entry in warningCounts.entries)
            Text(
              '${legacyWarningLabel(entry.key)} (${legacyDigits(entry.value)})',
            ),
        ],
      ),
    );
  }
}
