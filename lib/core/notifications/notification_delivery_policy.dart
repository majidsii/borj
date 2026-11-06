import 'notification_request.dart';

final class NotificationDeliveryContent {
  const NotificationDeliveryContent({required this.title, required this.body});

  final String title;
  final String body;
}

final class NotificationDeliveryPolicy {
  const NotificationDeliveryPolicy._();

  static NotificationDeliveryContent contentFor(NotificationRequest request) {
    return switch (request.privacyMode) {
      NotificationPrivacyMode.full => NotificationDeliveryContent(
        title: request.title,
        body: request.body,
      ),
      NotificationPrivacyMode.private => const NotificationDeliveryContent(
        title: 'برج',
        body: 'یک یادآور جدید دارید.',
      ),
    };
  }
}
