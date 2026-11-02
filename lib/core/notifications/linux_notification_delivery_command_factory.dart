import 'linux_systemd_notification_unit.dart';
import 'notification_request.dart';

/// Creates the shell-free command model used by one Linux systemd unit.
abstract interface class LinuxNotificationDeliveryCommandFactory {
  Future<LinuxSystemdNotificationUnit> create(NotificationRequest request);
}
