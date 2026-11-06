import 'package:borj/core/notifications/native_notification_gateway.dart';

final class NativeGatewayCall {
  const NativeGatewayCall({
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

final class FakeNativeNotificationGateway implements NativeNotificationGateway {
  final List<NativeGatewayCall> calls = <NativeGatewayCall>[];
  final List<NativePendingNotification> pendingItems =
      <NativePendingNotification>[];

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    calls.add(
      NativeGatewayCall(
        kind: 'show',
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
    calls.add(
      NativeGatewayCall(
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
    calls.add(NativeGatewayCall(kind: 'cancel', id: id));
    pendingItems.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<NativePendingNotification>> pending() async {
    return List<NativePendingNotification>.unmodifiable(pendingItems);
  }
}
