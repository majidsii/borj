import 'package:borj/core/notifications/linux_systemd_environment.dart';
import 'package:borj/core/notifications/linux_systemd_user_unit_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxSystemdUserUnitPathResolver', () {
    test('prefers non-empty XDG_CONFIG_HOME', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': '/tmp/custom-config',
          'HOME': '/home/tester',
        }),
      );

      expect(resolver.resolve(), '/tmp/custom-config/systemd/user');
    });

    test('falls back to HOME dot config', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{'HOME': '/home/tester'}),
      );

      expect(resolver.resolve(), '/home/tester/.config/systemd/user');
    });

    test('treats whitespace-only XDG_CONFIG_HOME as missing', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': '   ',
          'HOME': '/home/tester',
        }),
      );

      expect(resolver.resolve(), '/home/tester/.config/systemd/user');
    });

    test('treats empty XDG_CONFIG_HOME as missing', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': '',
          'HOME': '/home/tester',
        }),
      );

      expect(resolver.resolve(), '/home/tester/.config/systemd/user');
    });

    test('trims surrounding whitespace from absolute values', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': '  /tmp/config  ',
        }),
      );

      expect(resolver.resolve(), '/tmp/config/systemd/user');
    });

    test('removes trailing slashes before appending suffix', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': '/tmp/config///',
        }),
      );

      expect(resolver.resolve(), '/tmp/config/systemd/user');
    });

    test('supports filesystem root as XDG_CONFIG_HOME', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{'XDG_CONFIG_HOME': '/'}),
      );

      expect(resolver.resolve(), '/systemd/user');
    });

    test('supports filesystem root as HOME', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{'HOME': '/'}),
      );

      expect(resolver.resolve(), '/.config/systemd/user');
    });

    test('rejects missing configuration bases', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(const <String, String>{}),
      );

      expect(
        resolver.resolve,
        throwsA(isA<LinuxSystemdConfigurationException>()),
      );
    });

    test('rejects whitespace-only configuration bases', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': ' ',
          'HOME': '\t',
        }),
      );

      expect(
        resolver.resolve,
        throwsA(isA<LinuxSystemdConfigurationException>()),
      );
    });

    test('rejects a defined relative XDG_CONFIG_HOME', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': 'relative/config',
          'HOME': '/home/tester',
        }),
      );

      expect(
        resolver.resolve,
        throwsA(
          isA<LinuxSystemdConfigurationException>().having(
            (error) => error.variableName,
            'variableName',
            'XDG_CONFIG_HOME',
          ),
        ),
      );
    });

    test('rejects control characters in a configuration base', () {
      final resolver = LinuxSystemdUserUnitPathResolver(
        MapLinuxSystemdEnvironment(<String, String>{
          'XDG_CONFIG_HOME': '/tmp/config\nother',
        }),
      );

      expect(
        resolver.resolve,
        throwsA(
          isA<LinuxSystemdConfigurationException>().having(
            (error) => error.variableName,
            'variableName',
            'XDG_CONFIG_HOME',
          ),
        ),
      );
    });
  });
}

final class MapLinuxSystemdEnvironment implements LinuxSystemdEnvironment {
  const MapLinuxSystemdEnvironment(this._values);

  final Map<String, String> _values;

  @override
  String? value(String name) => _values[name];
}
