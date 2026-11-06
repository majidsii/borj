#!/usr/bin/env python3
from pathlib import Path
import re


def sort_imports(source: str, required: set[str]) -> str:
    lines = source.splitlines()
    imports = {line for line in lines if line.startswith('import ')}
    imports.update(required)
    non_imports = [line for line in lines if not line.startswith('import ')]
    while non_imports and not non_imports[0].strip():
        non_imports.pop(0)
    return '\n'.join(sorted(imports) + [''] + non_imports).rstrip() + '\n'


driver_path = Path(
    'lib/core/notifications/flutter_local_notifications_driver.dart'
)
driver = driver_path.read_text(encoding='utf-8')
driver = sort_imports(
    driver,
    {
        "import 'notification_host_platform.dart';",
        "import 'notification_permission.dart';",
    },
)

driver = driver.replace(
    'implements LocalNotificationsDriver, NativeNotificationGateway {',
    'implements\n'
    '        LocalNotificationsDriver,\n'
    '        NativeNotificationGateway,\n'
    '        NotificationPermissionGateway {',
    1,
)

constructor_pattern = re.compile(
    r'''  factory FlutterLocalNotificationsDriver\(\{
    required LocalNotificationPluginConfig config,
    FlutterLocalNotificationsPlugin\? plugin,
    NotificationPayloadHandler\? onPayload,
  \}\) \{
    return FlutterLocalNotificationsDriver\._\(
      config,
      plugin \?\? FlutterLocalNotificationsPlugin\(\),
      onPayload,
    \);
  \}

  FlutterLocalNotificationsDriver\._\(
    this\._config,
    this\._plugin,
    this\._onPayload,
  \);''',
    re.MULTILINE,
)

constructor_replacement = '''  factory FlutterLocalNotificationsDriver({
    required LocalNotificationPluginConfig config,
    required NotificationHostPlatform hostPlatform,
    FlutterLocalNotificationsPlugin? plugin,
    NotificationPayloadHandler? onPayload,
  }) {
    return FlutterLocalNotificationsDriver._(
      config,
      hostPlatform,
      plugin ?? FlutterLocalNotificationsPlugin(),
      onPayload,
    );
  }

  FlutterLocalNotificationsDriver._(
    this._config,
    this._hostPlatform,
    this._plugin,
    this._onPayload,
  );'''

if constructor_pattern.search(driver):
    driver = constructor_pattern.sub(
        constructor_replacement,
        driver,
        count=1,
    )
elif 'required NotificationHostPlatform hostPlatform' not in driver:
    raise SystemExit('Flutter driver constructor block was not found.')

field_anchor = '  final LocalNotificationPluginConfig _config;\n'
if 'final NotificationHostPlatform _hostPlatform;' not in driver:
    if field_anchor not in driver:
        raise SystemExit('Flutter driver field anchor was not found.')
    driver = driver.replace(
        field_anchor,
        field_anchor + '  final NotificationHostPlatform _hostPlatform;\n',
        1,
    )

permission_methods = r'''
  @override
  Future<NotificationPermissionStatus> status() async {
    return switch (_hostPlatform) {
      NotificationHostPlatform.android =>
        notificationPermissionStatusFromNullableBool(
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled(),
        ),
      NotificationHostPlatform.macos => _macOSPermissionStatus(),
      NotificationHostPlatform.linux ||
      NotificationHostPlatform.windows =>
        NotificationPermissionStatus.notRequired,
      NotificationHostPlatform.unsupported =>
        NotificationPermissionStatus.unavailable,
    };
  }

  @override
  Future<NotificationPermissionStatus> request() async {
    return switch (_hostPlatform) {
      NotificationHostPlatform.android =>
        notificationPermissionStatusFromNullableBool(
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission(),
        ),
      NotificationHostPlatform.macos =>
        notificationPermissionStatusFromNullableBool(
          await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ),
        ),
      NotificationHostPlatform.linux ||
      NotificationHostPlatform.windows =>
        NotificationPermissionStatus.notRequired,
      NotificationHostPlatform.unsupported =>
        NotificationPermissionStatus.unavailable,
    };
  }

  Future<NotificationPermissionStatus> _macOSPermissionStatus() async {
    final options = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();

    if (options == null) {
      return NotificationPermissionStatus.unavailable;
    }
    return options.isEnabled
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }
'''

if 'Future<NotificationPermissionStatus> status()' not in driver:
    class_end = driver.rfind('}')
    if class_end == -1:
        raise SystemExit('Flutter driver class end was not found.')
    driver = (
        driver[:class_end].rstrip()
        + '\n\n'
        + permission_methods.strip()
        + '\n'
        + driver[class_end:]
    )

driver_path.write_text(driver, encoding='utf-8')

providers_path = Path('lib/core/providers/persistence_providers.dart')
providers = providers_path.read_text(encoding='utf-8')
providers = sort_imports(
    providers,
    {
        "import 'package:borj/core/notifications/notification_permission.dart';",
        "import 'package:borj/core/notifications/notification_permission_service.dart';",
    },
)

driver_provider_pattern = re.compile(
    r'''final flutterLocalNotificationsDriverProvider =
    Provider<FlutterLocalNotificationsDriver>\(\(ref\) \{
      return FlutterLocalNotificationsDriver\(
        config: ref\.watch\(localNotificationPluginConfigProvider\),
      \);
    \}\);''',
    re.MULTILINE,
)

driver_provider_replacement = '''final flutterLocalNotificationsDriverProvider =
    Provider<FlutterLocalNotificationsDriver>((ref) {
      return FlutterLocalNotificationsDriver(
        config: ref.watch(localNotificationPluginConfigProvider),
        hostPlatform: ref.watch(notificationHostPlatformProvider),
      );
    });'''

if driver_provider_pattern.search(providers):
    providers = driver_provider_pattern.sub(
        driver_provider_replacement,
        providers,
        count=1,
    )
elif (
    'hostPlatform: ref.watch(notificationHostPlatformProvider)'
    not in providers
):
    raise SystemExit('Flutter notification driver provider was not found.')

blocks = {
    'notificationPermissionGatewayProvider': '''
final notificationPermissionGatewayProvider =
    Provider<NotificationPermissionGateway>((ref) {
      return ref.watch(flutterLocalNotificationsDriverProvider);
    });
''',
    'notificationPermissionServiceProvider': '''
final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
      return NotificationPermissionService(
        permissionGateway: ref.watch(
          notificationPermissionGatewayProvider,
        ),
        notificationGateway: ref.watch(
          nativeNotificationGatewayProvider,
        ),
      );
    });
''',
    'notificationPermissionHealthProvider': '''
final notificationPermissionHealthProvider =
    FutureProvider<NotificationPermissionHealth>((ref) {
      return ref.watch(notificationPermissionServiceProvider).health();
    });
''',
}

for name, block in blocks.items():
    if f'final {name}' not in providers:
        providers = providers.rstrip() + '\n\n' + block.strip() + '\n'

providers_path.write_text(providers, encoding='utf-8')

print('Phase 1 Task 8 permission wiring applied.')
