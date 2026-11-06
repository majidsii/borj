import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_notification_schedule_repository.dart';

void main() {
  test('getById uses exact case-sensitive schedule ID lookup', () async {
    final repository = MemoryNotificationScheduleRepository();
    final request = NotificationRequest(
      scheduleId: 'task-exact',
      owner: NotificationOwner(type: NotificationOwnerType.task, id: 'task-42'),
      title: 'Exact lookup',
      body: 'Persisted body',
      scheduledAtUtc: DateTime.utc(2026, 8, 2, 12),
      payload: const <String, String>{
        'route': '/tasks/task-42',
        'source': 'memory-test',
      },
      privacyMode: NotificationPrivacyMode.private,
    );

    try {
      await repository.upsert(request);

      expect(await repository.getById('task-exact'), same(request));
      expect(await repository.getById('TASK-EXACT'), isNull);
      expect(await repository.getById('task-exact '), isNull);
      expect(await repository.getById('missing'), isNull);
    } finally {
      await repository.dispose();
    }
  });
}
