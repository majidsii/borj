import 'dart:convert';
import 'dart:typed_data';

import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/legacy_import/domain/legacy_snapshot.dart';
import 'package:cryptography/cryptography.dart';

/// Parses v1's `data.json` (string-encoded values, or already-structured
/// values) and v1's two JSON export files into a [LegacySnapshot].
///
/// Row-level problems never abort parsing: the row is recorded in
/// [LegacySnapshot.skipped] or [LegacySnapshot.warnings].
final class LegacyV1Parser {
  const LegacyV1Parser();

  static const Set<String> _storageKeys = <String>{
    'tasklist:v1',
    'tasklist:prefs:v1',
    'finance:v1',
    'app:prefs:v1',
  };
  static const int _maxInt64 = 9223372036854775807;
  static const int _maxJsEpochMs = 8640000000000000;

  Future<LegacySnapshot> parseBytes(Uint8List bytes) async {
    final sha256 = await _hex(Sha256(), bytes);

    final Object? root;
    try {
      var text = utf8.decode(bytes);
      if (text.startsWith('﻿')) text = text.substring(1);
      root = jsonDecode(text);
    } on FormatException {
      throw const ImportFailure('فایل انتخاب‌شده JSON معتبر نیست.');
    }
    if (root is! Map<String, Object?>) {
      throw const ImportFailure('ساختار فایل انتخاب‌شده قابل شناسایی نیست.');
    }

    final sink = _Sink();
    if (root.isEmpty || _storageKeys.any(root.containsKey)) {
      return _parseDataJson(root, sha256, sink);
    }
    if (root['tasks'] is List ||
        root['transactions'] is List ||
        root['debts'] is List ||
        root['installments'] is List) {
      return _parseExport(root, sha256, sink);
    }
    throw const ImportFailure('ساختار فایل انتخاب‌شده قابل شناسایی نیست.');
  }

  Future<LegacySnapshot> _parseDataJson(
    Map<String, Object?> root,
    String sha256,
    _Sink sink,
  ) async {
    final tasksValue = _decode(root['tasklist:v1']);
    if (tasksValue.unreadable ||
        (tasksValue.value != null && tasksValue.value is! List)) {
      sink.warn(LegacyWarningCode.tasksUnreadable);
    }
    final financeValue = _decode(root['finance:v1']);
    final finance = financeValue.value;
    if (financeValue.unreadable ||
        (finance != null && finance is! Map<String, Object?>)) {
      sink.warn(LegacyWarningCode.financeUnreadable);
    }
    final financeMap = finance is Map<String, Object?>
        ? finance
        : const <String, Object?>{};
    final prefs = _decode(root['tasklist:prefs:v1']).value;
    final sort = prefs is Map<String, Object?> ? prefs['sort'] : null;

    return LegacySnapshot(
      sourceKind: LegacySourceKind.dataJson,
      sourceSha256: sha256,
      taskSort: switch (sort) {
        'pri' => LegacyTaskSort.priority,
        'abc' => LegacyTaskSort.alphabetical,
        _ => LegacyTaskSort.newest,
      },
      tasks: await _tasks(tasksValue.value, sink),
      transactions: await _transactions(financeMap['tx'], sink),
      debts: await _debts(financeMap['debts'], sink),
      installments: await _installments(financeMap['insts'], sink),
      skipped: sink.skipped,
      warnings: sink.warnings,
    );
  }

  Future<LegacySnapshot> _parseExport(
    Map<String, Object?> root,
    String sha256,
    _Sink sink,
  ) async {
    final exportedAt = root['exportedAt'];
    return LegacySnapshot(
      sourceKind: LegacySourceKind.export,
      sourceSha256: sha256,
      taskSort: LegacyTaskSort.newest,
      exportedAtUtc: exportedAt is String
          ? DateTime.tryParse(exportedAt)?.toUtc()
          : null,
      tasks: await _tasks(_normalize(root['tasks'], _exportTask), sink),
      transactions: await _transactions(
        _normalize(root['transactions'], _exportTransaction),
        sink,
      ),
      debts: await _debts(_normalize(root['debts'], _exportDebt), sink),
      installments: await _installments(
        _normalize(root['installments'], _exportInstallment),
        sink,
      ),
      skipped: sink.skipped,
      warnings: sink.warnings,
    );
  }

  // ---- export normalization: rewrite export records into data.json shape ----

  static Object? _normalize(
    Object? raw,
    Map<String, Object?> Function(Map<String, Object?>) convert,
  ) {
    if (raw is! List) return null;
    return raw
        .map((item) => item is Map<String, Object?> ? convert(item) : item)
        .toList();
  }

  static Map<String, Object?> _exportTask(Map<String, Object?> item) {
    return <String, Object?>{
      'text': item['text'],
      'done': item['done'],
      'priority': switch (item['priority']) {
        'low' => 1,
        'medium' => 2,
        'high' => 3,
        _ => 0,
      },
      'created': _isoToEpochMs(item['createdAt']),
    };
  }

  static Map<String, Object?> _exportTransaction(Map<String, Object?> item) {
    return <String, Object?>{
      'type': switch (item['type']) {
        'income' => 'in',
        'expense' => 'ex',
        final other => other,
      },
      'title': item['title'],
      'cat': item['category'],
      'amount': item['amount'],
      'ts': _isoToEpochMs(item['at']),
    };
  }

  static Map<String, Object?> _exportDebt(Map<String, Object?> item) {
    return <String, Object?>{
      'name': item['name'],
      'total': item['total'],
      'paid': item['paid'],
    };
  }

  static Map<String, Object?> _exportInstallment(Map<String, Object?> item) {
    return <String, Object?>{
      'name': item['name'],
      'per': item['perInstallment'],
      'count': item['count'],
      'paidCount': item['paidCount'],
    };
  }

  static int? _isoToEpochMs(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.millisecondsSinceEpoch;
  }

  // ---- entities ----

  Future<List<LegacyTask>> _tasks(Object? raw, _Sink sink) async {
    final result = <LegacyTask>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(LegacyEntityType.task, null, LegacySkipReason.notAnObject);
        continue;
      }
      final id = await _idFor(LegacyEntityType.task, item);
      final title = _text(item['text']) ?? '';
      if (title.isEmpty) {
        sink.skip(LegacyEntityType.task, id, LegacySkipReason.emptyTitle);
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(LegacyEntityType.task, id, LegacySkipReason.duplicateId);
        continue;
      }
      final priority = _wholeNumber(item['priority']);
      result.add(
        LegacyTask(
          v1Id: id,
          title: title,
          done: _truthy(item['done']),
          priority: priority != null && priority >= 0 && priority <= 3
              ? priority
              : (_truthy(item['important']) ? 3 : 0),
          createdAtUtc: _epochMs(item['created']),
        ),
      );
    }
    return result;
  }

  Future<List<LegacyTransaction>> _transactions(Object? raw, _Sink sink) async {
    final result = <LegacyTransaction>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(
          LegacyEntityType.transaction,
          null,
          LegacySkipReason.notAnObject,
        );
        continue;
      }
      final id = await _idFor(LegacyEntityType.transaction, item);
      final amount = _positiveInt(item['amount']);
      if (amount == null) {
        sink.skip(
          LegacyEntityType.transaction,
          id,
          LegacySkipReason.invalidAmount,
        );
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(
          LegacyEntityType.transaction,
          id,
          LegacySkipReason.duplicateId,
        );
        continue;
      }
      final type = item['type'];
      if (type != 'in' && type != 'ex') {
        sink.warn(
          LegacyWarningCode.unknownTransactionType,
          LegacyEntityType.transaction,
          id,
        );
      }
      result.add(
        LegacyTransaction(
          v1Id: id,
          title: _nonEmpty(item['title'], 'بدون عنوان'),
          category: _nonEmpty(item['cat'], 'سایر'),
          isIncome: type == 'in',
          amountToman: amount,
          occurredAtUtc: _epochMs(item['ts']),
        ),
      );
    }
    return result;
  }

  Future<List<LegacyDebt>> _debts(Object? raw, _Sink sink) async {
    final result = <LegacyDebt>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(LegacyEntityType.debt, null, LegacySkipReason.notAnObject);
        continue;
      }
      final id = await _idFor(LegacyEntityType.debt, item);
      final total = _positiveInt(item['total']);
      if (total == null) {
        sink.skip(LegacyEntityType.debt, id, LegacySkipReason.invalidAmount);
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(LegacyEntityType.debt, id, LegacySkipReason.duplicateId);
        continue;
      }
      final paidRaw = _wholeNumber(item['paid']) ?? 0;
      final paid = paidRaw < 0 ? 0 : (paidRaw > total ? total : paidRaw);
      if (paid != paidRaw) {
        sink.warn(LegacyWarningCode.paidClamped, LegacyEntityType.debt, id);
      }
      result.add(
        LegacyDebt(
          v1Id: id,
          title: _nonEmpty(item['name'], 'بدون عنوان'),
          totalToman: total,
          paidToman: paid,
          createdAtUtc: _epochMs(item['created']),
        ),
      );
    }
    return result;
  }

  Future<List<LegacyInstallment>> _installments(Object? raw, _Sink sink) async {
    final result = <LegacyInstallment>[];
    if (raw is! List) return result;
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?>) {
        sink.skip(
          LegacyEntityType.installment,
          null,
          LegacySkipReason.notAnObject,
        );
        continue;
      }
      final id = await _idFor(LegacyEntityType.installment, item);
      final per = _positiveInt(item['per']);
      if (per == null) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.invalidAmount,
        );
        continue;
      }
      final count = _positiveInt(item['count']);
      if (count == null) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.invalidCount,
        );
        continue;
      }
      if (BigInt.from(per) * BigInt.from(count) > BigInt.from(_maxInt64)) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.totalOverflow,
        );
        continue;
      }
      if (!seen.add(id)) {
        sink.skip(
          LegacyEntityType.installment,
          id,
          LegacySkipReason.duplicateId,
        );
        continue;
      }
      final paidRaw = _wholeNumber(item['paidCount']) ?? 0;
      final paid = paidRaw < 0 ? 0 : (paidRaw > count ? count : paidRaw);
      if (paid != paidRaw) {
        sink.warn(
          LegacyWarningCode.paidCountClamped,
          LegacyEntityType.installment,
          id,
        );
      }
      result.add(
        LegacyInstallment(
          v1Id: id,
          title: _nonEmpty(item['name'], 'بدون عنوان'),
          perToman: per,
          count: count,
          paidCount: paid,
          createdAtUtc: _epochMs(item['created']),
        ),
      );
    }
    return result;
  }

  // ---- helpers ----

  static _Decoded _decode(Object? raw) {
    if (raw == null) return const _Decoded(null, unreadable: false);
    if (raw is String) {
      try {
        return _Decoded(jsonDecode(raw), unreadable: false);
      } on FormatException {
        return const _Decoded(null, unreadable: true);
      }
    }
    return _Decoded(raw, unreadable: false);
  }

  static Future<String> _idFor(
    LegacyEntityType type,
    Map<String, Object?> item,
  ) async {
    final raw = item['id'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is int) return '$raw';
    final canonical = jsonEncode(_canonical(item));
    final digest = await _hex(Sha1(), utf8.encode(canonical));
    return 'v1:${type.storageValue}:$digest';
  }

  /// Rebuilds [value] with map keys sorted so equal records hash equally.
  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => '$key').toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonical(value[key]),
      };
    }
    if (value is List) return value.map(_canonical).toList();
    return value;
  }

  static Future<String> _hex(HashAlgorithm algorithm, List<int> data) async {
    final hash = await algorithm.hash(data);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String? _text(Object? value) => value is String ? value.trim() : null;

  static String _nonEmpty(Object? value, String fallback) {
    final text = _text(value);
    return text == null || text.isEmpty ? fallback : text;
  }

  static bool _truthy(Object? value) =>
      value == true ||
      (value is num && value != 0) ||
      (value is String && value.isNotEmpty);

  static int? _wholeNumber(Object? value) {
    if (value is int) return value;
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble() &&
        value.abs() < 9007199254740992) {
      return value.toInt();
    }
    return null;
  }

  static int? _positiveInt(Object? value) {
    final number = _wholeNumber(value);
    return number != null && number > 0 ? number : null;
  }

  static DateTime? _epochMs(Object? value) {
    final number = _wholeNumber(value);
    if (number == null || number <= 0 || number > _maxJsEpochMs) return null;
    return DateTime.fromMillisecondsSinceEpoch(number, isUtc: true);
  }
}

final class _Decoded {
  const _Decoded(this.value, {required this.unreadable});

  final Object? value;
  final bool unreadable;
}

final class _Sink {
  final List<LegacySkippedRow> skipped = <LegacySkippedRow>[];
  final List<LegacyWarning> warnings = <LegacyWarning>[];

  void skip(LegacyEntityType type, String? v1Id, LegacySkipReason reason) {
    skipped.add(LegacySkippedRow(entityType: type, v1Id: v1Id, reason: reason));
  }

  void warn(LegacyWarningCode code, [LegacyEntityType? type, String? v1Id]) {
    warnings.add(LegacyWarning(code: code, entityType: type, v1Id: v1Id));
  }
}
