import 'package:borj/app/theme/original_theme.dart';
import 'package:borj/features/legacy_import/domain/legacy_import_report.dart';
import 'package:borj/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<LegacyEntityType, int> _counts({
  int task = 0,
  int transaction = 0,
  int debt = 0,
  int installment = 0,
}) => <LegacyEntityType, int>{
  LegacyEntityType.task: task,
  LegacyEntityType.transaction: transaction,
  LegacyEntityType.debt: debt,
  LegacyEntityType.installment: installment,
};

Widget _host(void Function(BuildContext) onOpen) {
  return MaterialApp(
    theme: OriginalTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey<String>('open'),
              onPressed: () => onOpen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('open')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

void main() {
  testWidgets('preview shows counts, already-imported and skipped rows', (
    tester,
  ) async {
    bool? confirmed;
    final preview = LegacyImportPreview(
      toImport: _counts(task: 4, transaction: 2, debt: 1, installment: 1),
      alreadyImported: _counts(task: 3),
      skipped: const <LegacySkippedRow>[
        LegacySkippedRow(
          entityType: LegacyEntityType.task,
          v1Id: 'x',
          reason: LegacySkipReason.emptyTitle,
        ),
      ],
      warnings: const <LegacyWarning>[
        LegacyWarning(code: LegacyWarningCode.financeUnreadable),
      ],
    );

    await tester.pumpWidget(
      _host((context) async {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => LegacyImportPreviewDialog(preview: preview),
        );
      }),
    );
    await _pumpDialog(tester);

    expect(_text(tester, 'legacy-count-task'), '۴');
    expect(_text(tester, 'legacy-count-transaction'), '۲');
    expect(_text(tester, 'legacy-count-debt'), '۱');
    expect(_text(tester, 'legacy-count-installment'), '۱');
    expect(_text(tester, 'legacy-count-already-task'), contains('۳'));
    expect(find.text('کار: عنوان خالی (۱)'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('legacy-issues')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-confirm')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(confirmed, isTrue);
  });

  testWidgets('cancel returns false', (tester) async {
    bool? confirmed;
    final preview = LegacyImportPreview(
      toImport: _counts(task: 1),
      alreadyImported: _counts(),
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );

    await tester.pumpWidget(
      _host((context) async {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => LegacyImportPreviewDialog(preview: preview),
        );
      }),
    );
    await _pumpDialog(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('legacy-import-cancel')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(confirmed, isFalse);
  });

  testWidgets('nothing new hides the confirm button', (tester) async {
    final preview = LegacyImportPreview(
      toImport: _counts(),
      alreadyImported: _counts(task: 4),
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );

    await tester.pumpWidget(
      _host((context) {
        showDialog<bool>(
          context: context,
          builder: (_) => LegacyImportPreviewDialog(preview: preview),
        );
      }),
    );
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('legacy-nothing-new')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('legacy-import-confirm')),
      findsNothing,
    );
  });

  testWidgets('report shows what was imported', (tester) async {
    final report = LegacyImportReport(
      imported: _counts(task: 4, transaction: 2),
      alreadyImported: _counts(),
      skipped: const <LegacySkippedRow>[],
      warnings: const <LegacyWarning>[],
    );

    await tester.pumpWidget(
      _host((context) {
        showDialog<void>(
          context: context,
          builder: (_) => LegacyImportReportDialog(report: report),
        );
      }),
    );
    await _pumpDialog(tester);

    expect(_text(tester, 'legacy-report-count-task'), '۴');
    expect(_text(tester, 'legacy-report-count-transaction'), '۲');
    expect(
      find.byKey(const ValueKey<String>('legacy-import-close')),
      findsOneWidget,
    );
  });
}
