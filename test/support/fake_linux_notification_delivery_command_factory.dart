import 'package:dashboard_shakhsi/core/notifications/linux_notification_delivery_command_factory.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_notification_unit.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_request.dart';

final class FakeLinuxNotificationDeliveryCommandFactory
    implements LinuxNotificationDeliveryCommandFactory {
  FakeLinuxNotificationDeliveryCommandFactory({
    required this.result,
    this.error,
    this.errorStackTrace,
  });

  final LinuxSystemdNotificationUnit result;
  Object? error;
  StackTrace? errorStackTrace;

  final List<NotificationRequest> requests = <NotificationRequest>[];

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    requests.add(request);

    final configuredError = error;
    if (configuredError != null) {
      final configuredStackTrace = errorStackTrace;
      if (configuredStackTrace != null) {
        Error.throwWithStackTrace(configuredError, configuredStackTrace);
      }

      throw configuredError;
    }

    return result;
  }
}
