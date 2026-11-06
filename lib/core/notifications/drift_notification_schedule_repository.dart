import 'dart:convert';

import 'package:borj/core/database/app_database.dart';
import 'package:borj/core/date_time/app_clock.dart';
import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';
import 'package:drift/drift.dart';

final class DriftNotificationScheduleRepository
    implements NotificationScheduleRepository {
  factory DriftNotificationScheduleRepository(
    AppDatabase database, {
    AppClock clock = const SystemAppClock(),
  }) {
    return DriftNotificationScheduleRepository._(database, clock);
  }

  const DriftNotificationScheduleRepository._(this._database, this._clock);

  final AppDatabase _database;
  final AppClock _clock;

  @override
  Stream<List<NotificationRequest>> watchAll() {
    final query = _database.select(_database.notificationScheduleRows)
      ..orderBy(<OrderingTerm Function(NotificationScheduleRows)>[
        (row) => OrderingTerm.asc(row.scheduledAtUtc),
        (row) => OrderingTerm.asc(row.scheduleId),
      ]);

    return query.watch().map(
      (rows) => rows.map(_requestFromRow).toList(growable: false),
    );
  }

  @override
  Future<List<NotificationRequest>> getAll() async {
    final query = _database.select(_database.notificationScheduleRows)
      ..orderBy(<OrderingTerm Function(NotificationScheduleRows)>[
        (row) => OrderingTerm.asc(row.scheduledAtUtc),
        (row) => OrderingTerm.asc(row.scheduleId),
      ]);

    final rows = await query.get();
    return rows.map(_requestFromRow).toList(growable: false);
  }

  @override
  Future<NotificationRequest?> getById(String scheduleId) async {
    final row = await (_database.select(
      _database.notificationScheduleRows,
    )..where((item) => item.scheduleId.equals(scheduleId))).getSingleOrNull();

    return row == null ? null : _requestFromRow(row);
  }

  @override
  Future<void> upsert(NotificationRequest request) async {
    final nowUtc = _clock.nowUtc().toUtc();
    await _upsert(request, nowUtc: nowUtc);
  }

  @override
  Future<void> delete(String scheduleId) async {
    await (_database.delete(
      _database.notificationScheduleRows,
    )..where((row) => row.scheduleId.equals(scheduleId))).go();
  }

  @override
  Future<void> deleteByOwner(NotificationOwner owner) async {
    await (_database.delete(_database.notificationScheduleRows)..where(
          (row) =>
              row.ownerType.equals(owner.type.name) &
              row.ownerId.equals(owner.id),
        ))
        .go();
  }

  @override
  Future<void> replaceAll(List<NotificationRequest> expected) {
    final desiredById = <String, NotificationRequest>{
      for (final request in expected) request.scheduleId: request,
    };
    final nowUtc = _clock.nowUtc().toUtc();

    return _database.transaction(() async {
      final existingRows = await _database
          .select(_database.notificationScheduleRows)
          .get();

      for (final row in existingRows) {
        if (!desiredById.containsKey(row.scheduleId)) {
          await (_database.delete(
            _database.notificationScheduleRows,
          )..where((item) => item.scheduleId.equals(row.scheduleId))).go();
        }
      }

      for (final request in desiredById.values) {
        await _upsert(request, nowUtc: nowUtc);
      }
    });
  }

  Future<void> _upsert(
    NotificationRequest request, {
    required DateTime nowUtc,
  }) async {
    final existing =
        await (_database.select(_database.notificationScheduleRows)
              ..where((row) => row.scheduleId.equals(request.scheduleId)))
            .getSingleOrNull();

    await _database
        .into(_database.notificationScheduleRows)
        .insertOnConflictUpdate(
          NotificationScheduleRowsCompanion(
            scheduleId: Value<String>(request.scheduleId),
            ownerType: Value<String>(request.owner.type.name),
            ownerId: Value<String>(request.owner.id),
            title: Value<String>(request.title),
            body: Value<String>(request.body),
            scheduledAtUtc: Value<DateTime>(request.scheduledAtUtc),
            payloadJson: Value<String>(jsonEncode(request.payload)),
            privacyMode: Value<String>(request.privacyMode.name),
            createdAtUtc: Value<DateTime>(
              existing?.createdAtUtc.toUtc() ?? nowUtc,
            ),
            updatedAtUtc: Value<DateTime>(nowUtc),
          ),
        );
  }
}

NotificationRequest _requestFromRow(NotificationScheduleRow row) {
  return NotificationRequest(
    scheduleId: row.scheduleId,
    owner: NotificationOwner(
      type: NotificationOwnerType.values.byName(row.ownerType),
      id: row.ownerId,
    ),
    title: row.title,
    body: row.body,
    scheduledAtUtc: row.scheduledAtUtc.toUtc(),
    payload: _decodePayload(row.payloadJson),
    privacyMode: NotificationPrivacyMode.values.byName(row.privacyMode),
  );
}

Map<String, String> _decodePayload(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Notification payload must be a JSON object.');
  }

  return decoded.map<String, String>((key, item) {
    if (item is! String) {
      throw const FormatException(
        'Notification payload values must be strings.',
      );
    }
    return MapEntry<String, String>(key, item);
  });
}
