final class LocalNotificationPluginConfig {
  factory LocalNotificationPluginConfig({
    required String appName,
    required String appUserModelId,
    required String windowsGuid,
    required String androidDefaultIcon,
    required String defaultActionName,
  }) {
    return LocalNotificationPluginConfig._(
      appName: _required(appName, 'appName'),
      appUserModelId: _required(appUserModelId, 'appUserModelId'),
      windowsGuid: _required(windowsGuid, 'windowsGuid'),
      androidDefaultIcon: _required(androidDefaultIcon, 'androidDefaultIcon'),
      defaultActionName: _required(defaultActionName, 'defaultActionName'),
    );
  }

  const LocalNotificationPluginConfig.defaults()
    : appName = 'برج',
      appUserModelId = 'Majidsii.Borj',
      windowsGuid = 'b9e6ab22-2f88-4fe8-bd44-2b19dc7d0371',
      androidDefaultIcon = 'ic_launcher',
      defaultActionName = 'باز کردن';

  const LocalNotificationPluginConfig._({
    required this.appName,
    required this.appUserModelId,
    required this.windowsGuid,
    required this.androidDefaultIcon,
    required this.defaultActionName,
  });

  final String appName;
  final String appUserModelId;
  final String windowsGuid;
  final String androidDefaultIcon;
  final String defaultActionName;

  static String _required(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName cannot be blank.',
      );
    }
    return normalized;
  }
}
