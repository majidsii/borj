import 'package:borj/core/notifications/notification_owner.dart';
import 'package:borj/core/notifications/notification_request.dart';
import 'package:borj/core/notifications/notification_scheduler.dart';

final class FakeNotificationScheduler implements NotificationScheduler {
  final Map<String, NotificationRequest> _requests =
      <String, NotificationRequest>{};

  List<NotificationRequest> get scheduledRequests {
    return List<NotificationRequest>.unmodifiable(_requests.values);
  }

  @override
  Future<void> cancel(String scheduleId) {
    _requests.remove(scheduleId);
    return Future<void>.value();
  }

  @override
  Future<void> cancelByOwner(NotificationOwner owner) {
    _requests.removeWhere((_, request) => request.owner == owner);
    return Future<void>.value();
  }

  @override
  Future<void> reconcile(List<NotificationRequest> expected) {
    final desired = <String, NotificationRequest>{};
    for (final request in expected) {
      desired[request.scheduleId] = request;
    }

    _requests
      ..clear()
      ..addAll(desired);

    return Future<void>.value();
  }

  @override
  Future<void> schedule(NotificationRequest request) {
    _requests[request.scheduleId] = request;
    return Future<void>.value();
  }
}
