import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry.dart';
import 'package:borj/core/notifications/linux_systemd_schedule_registry_store.dart';

final class FakeLinuxSystemdScheduleRegistryStore
    implements LinuxSystemdScheduleRegistryStore {
  FakeLinuxSystemdScheduleRegistryStore({
    required LinuxSystemdScheduleRegistry initial,
    List<String>? operations,
    LinuxSystemdUnitDiscovery? discovery,
  }) : current = initial,
       operations = operations ?? <String>[],
       discovery =
           discovery ??
           LinuxSystemdUnitDiscovery(
             completePairs: const <LinuxSystemdUnitNames>[],
             partialPairs: const <LinuxSystemdPartialUnitPair>[],
           );

  LinuxSystemdScheduleRegistry current;
  final List<String> operations;
  final LinuxSystemdUnitDiscovery discovery;
  final List<LinuxSystemdScheduleRegistry> replacements =
      <LinuxSystemdScheduleRegistry>[];

  int loadCount = 0;
  int quarantineCount = 0;
  int discoveryCount = 0;

  @override
  Future<LinuxSystemdScheduleRegistry> load() async {
    operations.add('registry.load');
    loadCount += 1;
    return current;
  }

  @override
  Future<void> replace(LinuxSystemdScheduleRegistry next) async {
    operations.add('registry.replace');
    replacements.add(next);
    current = next;
  }

  @override
  Future<void> quarantineCorruptRegistry() async {
    operations.add('registry.quarantine');
    quarantineCount += 1;
  }

  @override
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs() async {
    operations.add('registry.discover');
    discoveryCount += 1;
    return discovery;
  }
}
