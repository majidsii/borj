import 'dart:io';
import 'dart:typed_data';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/legacy_import/data/legacy_v1_parser.dart';
import 'package:borj/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> fixture(String name) =>
    File('test/fixtures/legacy_v1/$name').readAsBytes();

Future<LegacySnapshot> parse(String name) async =>
    const LegacyV1Parser().parseBytes(await fixture(name));

DateTime ms(int value) =>
    DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

void main() {
  group('data.json (double-encoded values)', () {
    test('v1.2 desktop file parses every entity exactly', () async {
      final snapshot = await parse('data_v1_2_desktop.json');

      expect(snapshot.sourceKind, LegacySourceKind.dataJson);
      expect(snapshot.taskSort, LegacyTaskSort.newest);
      expect(snapshot.exportedAtUtc, isNull);
      expect(snapshot.skipped, isEmpty);
      expect(snapshot.warnings, isEmpty);

      expect(snapshot.tasks.map((t) => t.v1Id), <String>[
        '1730640000123-aaaaa',
        '1730500000000-bbbbb',
        '1730400000000-ccccc',
        '1730300000000-ddddd',
      ]);
      final first = snapshot.tasks.first;
      expect(first.title, 'خرید نان');
      expect(first.done, isFalse);
      expect(first.priority, 3);
      expect(first.createdAtUtc, ms(1730640000123));
      expect(snapshot.tasks[1].done, isTrue);

      expect(snapshot.transactions, hasLength(2));
      final expense = snapshot.transactions.first;
      expect(expense.v1Id, '1730641000000-aaaa1');
      expect(expense.isIncome, isFalse);
      expect(expense.category, 'بدهی');
      expect(expense.amountToman, 2000000);
      expect(expense.occurredAtUtc, ms(1730641000000));
      expect(snapshot.transactions.last.isIncome, isTrue);
      expect(snapshot.transactions.last.amountToman, 25000000);

      final debt = snapshot.debts.single;
      expect(debt.title, 'قرض از علی');
      expect(debt.totalToman, 10000000);
      expect(debt.paidToman, 2000000);
      expect(debt.createdAtUtc, ms(1730000000001));

      final installment = snapshot.installments.single;
      expect(installment.perToman, 3500000);
      expect(installment.count, 12);
      expect(installment.paidCount, 4);
    });

    test('v1.0 legacy file: important flag, missing id, blank title', () async {
      final snapshot = await parse('data_v1_0_legacy.json');

      expect(snapshot.taskSort, LegacyTaskSort.priority);
      expect(snapshot.tasks, hasLength(2));
      expect(snapshot.tasks.first.v1Id, '1700000000000-old01');
      expect(snapshot.tasks.first.priority, 3);
      expect(snapshot.tasks.last.v1Id, startsWith('v1:task:'));
      expect(snapshot.tasks.last.priority, 2);
      expect(snapshot.skipped, hasLength(1));
      expect(snapshot.skipped.single.reason, LegacySkipReason.emptyTitle);
      expect(snapshot.skipped.single.entityType, LegacyEntityType.task);
      expect(snapshot.transactions, isEmpty);
    });

    test('derived ids are deterministic across parses', () async {
      final first = await parse('data_v1_0_legacy.json');
      final second = await parse('data_v1_0_legacy.json');

      expect(first.tasks.last.v1Id, second.tasks.last.v1Id);
      expect(first.tasks.last.v1Id, matches(RegExp(r'^v1:task:[0-9a-f]{40}$')));
    });

    test('android compact single-line file parses', () async {
      final snapshot = await parse('data_android_compact.json');

      expect(snapshot.taskSort, LegacyTaskSort.alphabetical);
      expect(snapshot.tasks, hasLength(2));
      expect(snapshot.transactions.single.amountToman, 25000000);
      expect(snapshot.debts, isEmpty);
    });

    test('already-structured values parse like string-encoded ones', () async {
      final snapshot = await parse('data_structured_values.json');

      expect(snapshot.tasks.single.title, 'خرید نان');
      expect(snapshot.transactions.single.isIncome, isTrue);
    });

    test('edge cases skip bad rows and never abort', () async {
      final snapshot = await parse('data_edge_cases.json');

      expect(snapshot.tasks.map((t) => t.v1Id), <String>['dup-1']);
      expect(snapshot.transactions.map((t) => t.v1Id), <String>[
        'tx-unknown',
        'tx-huge',
        'tx-blank',
      ]);
      final unknown = snapshot.transactions.first;
      expect(unknown.isIncome, isFalse);
      final huge = snapshot.transactions[1];
      expect(huge.amountToman, 999999999999999);
      final blank = snapshot.transactions.last;
      expect(blank.title, 'بدون عنوان');
      expect(blank.category, 'سایر');

      final debt = snapshot.debts.single;
      expect(debt.v1Id, 'debt-over');
      expect(debt.paidToman, 1000);

      expect(snapshot.installments, hasLength(2));
      expect(snapshot.installments.first.v1Id, 'inst-paid-over');
      expect(snapshot.installments.first.paidCount, 3);
      expect(snapshot.installments.last.v1Id, startsWith('v1:installment:'));

      Map<LegacySkipReason, int> reasons(LegacyEntityType type) {
        final result = <LegacySkipReason, int>{};
        for (final row in snapshot.skipped.where((r) => r.entityType == type)) {
          result[row.reason] = (result[row.reason] ?? 0) + 1;
        }
        return result;
      }

      expect(reasons(LegacyEntityType.task), <LegacySkipReason, int>{
        LegacySkipReason.duplicateId: 1,
        LegacySkipReason.notAnObject: 1,
      });
      expect(reasons(LegacyEntityType.transaction), <LegacySkipReason, int>{
        LegacySkipReason.invalidAmount: 3,
      });
      expect(reasons(LegacyEntityType.debt), <LegacySkipReason, int>{
        LegacySkipReason.invalidAmount: 1,
      });
      expect(reasons(LegacyEntityType.installment), <LegacySkipReason, int>{
        LegacySkipReason.totalOverflow: 1,
        LegacySkipReason.invalidCount: 1,
      });
      expect(snapshot.skipped, hasLength(8));

      expect(snapshot.warnings.map((w) => w.code).toSet(), <LegacyWarningCode>{
        LegacyWarningCode.unknownTransactionType,
        LegacyWarningCode.paidClamped,
        LegacyWarningCode.paidCountClamped,
      });
      expect(snapshot.warnings, hasLength(3));
    });

    test('unreadable finance string keeps tasks and warns', () async {
      final snapshot = await parse('data_finance_unreadable.json');

      expect(snapshot.tasks, hasLength(1));
      expect(snapshot.transactions, isEmpty);
      expect(
        snapshot.warnings.single.code,
        LegacyWarningCode.financeUnreadable,
      );
    });

    test('an empty object is a valid empty snapshot', () async {
      final snapshot = await parse('empty_object.json');

      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.skipped, isEmpty);
    });

    test('the source hash is the sha256 of the file bytes', () async {
      final bytes = await fixture('data_v1_2_desktop.json');
      final expected = await Sha256().hash(bytes);
      final hex = expected.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      final snapshot = await const LegacyV1Parser().parseBytes(bytes);

      expect(snapshot.sourceSha256, hex);
      expect(snapshot.sourceSha256, hasLength(64));
    });
  });

  group('v1 export files', () {
    test('tasks export maps names, dates and priorities', () async {
      final snapshot = await parse('export_tasks.json');

      expect(snapshot.sourceKind, LegacySourceKind.export);
      expect(snapshot.exportedAtUtc, DateTime.utc(2026, 11, 1, 8, 30));
      expect(snapshot.tasks, hasLength(2));
      final first = snapshot.tasks.first;
      expect(first.title, 'خرید نان');
      expect(first.priority, 3);
      expect(first.done, isFalse);
      expect(first.createdAtUtc, DateTime.utc(2024, 11, 3, 13, 20, 0, 123));
      expect(first.v1Id, startsWith('v1:task:'));
      expect(snapshot.tasks.last.done, isTrue);
      expect(snapshot.tasks.last.priority, 0);
      expect(snapshot.tasks.last.createdAtUtc, ms(1730500000000));
    });

    test('finance export maps transactions, debts and installments', () async {
      final snapshot = await parse('export_finance.json');

      expect(snapshot.sourceKind, LegacySourceKind.export);
      expect(snapshot.transactions, hasLength(2));
      expect(snapshot.transactions.first.isIncome, isTrue);
      expect(snapshot.transactions.first.category, 'حقوق');
      expect(
        snapshot.transactions.first.occurredAtUtc,
        DateTime.utc(2024, 11, 2, 22, 40),
      );
      expect(snapshot.transactions.last.isIncome, isFalse);
      expect(snapshot.debts.single.totalToman, 10000000);
      expect(snapshot.debts.single.paidToman, 2000000);
      expect(snapshot.debts.single.createdAtUtc, isNull);
      expect(snapshot.installments.single.perToman, 3500000);
      expect(snapshot.installments.single.count, 12);
      expect(snapshot.installments.single.paidCount, 4);
      expect(snapshot.installments.single.createdAtUtc, isNull);
    });
  });

  group('unusable input', () {
    test('truncated JSON throws ImportFailure', () async {
      expect(
        () => parse('corrupt_truncated.json'),
        throwsA(isA<ImportFailure>()),
      );
    });

    test('a JSON array root throws ImportFailure', () async {
      expect(() => parse('not_object.json'), throwsA(isA<ImportFailure>()));
    });

    test('an unrecognized object throws ImportFailure', () async {
      expect(
        () => parse('unsupported_object.json'),
        throwsA(isA<ImportFailure>()),
      );
    });

    test('non UTF-8 bytes throw ImportFailure', () async {
      expect(
        () => const LegacyV1Parser().parseBytes(
          Uint8List.fromList(<int>[0xff, 0xfe, 0xfd]),
        ),
        throwsA(isA<ImportFailure>()),
      );
    });
  });
}
