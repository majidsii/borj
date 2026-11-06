import 'package:borj/core/notifications/native_notification_gateway.dart';

final class RecordingNativeNotificationCall {
  const RecordingNativeNotificationCall({
    required this.kind,
    required this.id,
    this.title,
    this.body,
    this.scheduledAtUtc,
    this.payload,
  });

  final String kind;
  final int id;
  final String? title;
  final String? body;
  final DateTime? scheduledAtUtc;
  final String? payload;
}

final class RecordingNativeNotificationGateway
    implements NativeNotificationGateway {
  RecordingNativeNotificationGateway({List<String>? operations})
    : operations = operations ?? <String>[];

  final List<String> operations;
  final List<RecordingNativeNotificationCall> calls =
      <RecordingNativeNotificationCall>[];
  final List<NativePendingNotification> pendingItems =
      <NativePendingNotification>[];

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    operations.add('gateway.showNow');
    calls.add(
      RecordingNativeNotificationCall(
        kind: 'showNow',
        id: id,
        title: title,
        body: body,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    required String payload,
  }) async {
    operations.add('gateway.schedule');
    calls.add(
      RecordingNativeNotificationCall(
        kind: 'schedule',
        id: id,
        title: title,
        body: body,
        scheduledAtUtc: scheduledAtUtc,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    operations.add('gateway.cancel');
    calls.add(RecordingNativeNotificationCall(kind: 'cancel', id: id));
    pendingItems.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<NativePendingNotification>> pending() async {
    operations.add('gateway.pending');
    return List<NativePendingNotification>.unmodifiable(pendingItems);
  }
}
