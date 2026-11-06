import 'package:borj/core/notifications/notification_permission.dart';

final class FakeNotificationPermissionGateway
    implements NotificationPermissionGateway {
  FakeNotificationPermissionGateway({
    required NotificationPermissionStatus status,
    NotificationPermissionStatus? requestResult,
  }) : _status = status,
       _requestResult = requestResult ?? status;

  NotificationPermissionStatus _status;
  final NotificationPermissionStatus _requestResult;

  int statusCallCount = 0;
  int requestCallCount = 0;

  @override
  Future<NotificationPermissionStatus> status() async {
    statusCallCount += 1;
    return _status;
  }

  @override
  Future<NotificationPermissionStatus> request() async {
    requestCallCount += 1;
    _status = _requestResult;
    return _status;
  }
}
