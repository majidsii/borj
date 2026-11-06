import 'dart:async';

import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_schedule_repository.dart';

final class MemoryNotificationScheduleRepository
    implements NotificationScheduleRepository {
  final Map<String, NotificationRequest> _items =
      <String, NotificationRequest>{};
  final StreamController<List<NotificationRequest>> _changes =
      StreamController<List<NotificationRequest>>.broadcast();

  List<NotificationRequest> get items => _snapshot();

  @override
  Stream<List<NotificationRequest>> watchAll() async* {
    yield _snapshot();
    yield* _changes.stream;
  }

  @override
  Future<List<NotificationRequest>> getAll() async => _snapshot();

  @override
  Future<NotificationRequest?> getById(String scheduleId) async {
    return _items[scheduleId];
  }

  @override
  Future<void> upsert(NotificationRequest request) async {
    _items[request.scheduleId] = request;
    _emit();
  }

  @override
  Future<void> delete(String scheduleId) async {
    _items.remove(scheduleId);
    _emit();
  }

  @override
  Future<void> deleteByOwner(NotificationOwner owner) async {
    _items.removeWhere((_, request) => request.owner == owner);
    _emit();
  }

  @override
  Future<void> replaceAll(List<NotificationRequest> expected) async {
    _items
      ..clear()
      ..addEntries(
        expected.map(
          (request) => MapEntry<String, NotificationRequest>(
            request.scheduleId,
            request,
          ),
        ),
      );
    _emit();
  }

  Future<void> dispose() => _changes.close();

  List<NotificationRequest> _snapshot() {
    final values = _items.values.toList(growable: false)
      ..sort((left, right) {
        final byTime = left.scheduledAtUtc.compareTo(right.scheduledAtUtc);
        if (byTime != 0) {
          return byTime;
        }
        return left.scheduleId.compareTo(right.scheduleId);
      });
    return List<NotificationRequest>.unmodifiable(values);
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(_snapshot());
    }
  }
}
