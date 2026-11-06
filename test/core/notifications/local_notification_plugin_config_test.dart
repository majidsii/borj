import 'package:borj/core/notifications/local_notification_plugin_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default plugin identity remains stable across releases', () {
    const config = LocalNotificationPluginConfig.defaults();

    expect(config.appName, 'برج');
    expect(config.appUserModelId, 'Majidsii.Borj');
    expect(config.windowsGuid, 'b9e6ab22-2f88-4fe8-bd44-2b19dc7d0371');
    expect(config.androidDefaultIcon, 'ic_launcher');
    expect(config.defaultActionName, 'باز کردن');
  });

  test('rejects blank native identity values', () {
    expect(
      () => LocalNotificationPluginConfig(
        appName: ' ',
        appUserModelId: 'Majidsii.Borj',
        windowsGuid: 'b9e6ab22-2f88-4fe8-bd44-2b19dc7d0371',
        androidDefaultIcon: 'ic_launcher',
        defaultActionName: 'باز کردن',
      ),
      throwsArgumentError,
    );
  });
}
