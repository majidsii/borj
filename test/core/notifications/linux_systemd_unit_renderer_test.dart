import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';
import 'package:borj/core/notifications/linux_systemd_unit_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinuxSystemdNotificationUnit', () {
    test('accepts a safe absolute executable and UTC schedule', () {
      final unit = LinuxSystemdNotificationUnit(
        scheduleKey: 'task:alpha/notification-1',
        scheduledAtUtc: DateTime.utc(2026, 7, 28, 18, 45, 6),
        executablePath: '/opt/Borj/borj',
        arguments: const <String>[
          '--deliver-notification',
          'task:alpha/notification-1',
        ],
      );

      expect(unit.scheduleKey, 'task:alpha/notification-1');
      expect(unit.scheduledAtUtc.isUtc, isTrue);
      expect(unit.arguments, isNot(same(const <String>[])));
    });

    test('copies arguments defensively', () {
      final arguments = <String>['--deliver-notification', 'schedule-1'];
      final unit = LinuxSystemdNotificationUnit(
        scheduleKey: 'schedule-1',
        scheduledAtUtc: DateTime.utc(2026, 7, 28),
        executablePath: '/opt/borj',
        arguments: arguments,
      );

      arguments.add('--unexpected');

      expect(unit.arguments, const <String>[
        '--deliver-notification',
        'schedule-1',
      ]);
      expect(() => unit.arguments.add('--mutation'), throwsUnsupportedError);
    });

    test('rejects an empty schedule key', () {
      expect(
        () => LinuxSystemdNotificationUnit(
          scheduleKey: '',
          scheduledAtUtc: DateTime.utc(2026, 7, 28),
          executablePath: '/opt/borj',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a schedule key longer than 512 UTF-8 bytes', () {
      expect(
        () => LinuxSystemdNotificationUnit(
          scheduleKey: List<String>.filled(513, 'a').join(),
          scheduledAtUtc: DateTime.utc(2026, 7, 28),
          executablePath: '/opt/borj',
        ),
        throwsArgumentError,
      );
    });

    test('rejects control characters in schedule key', () {
      for (final key in <String>[
        'task\nnext',
        'task\rnext',
        'task\u0000next',
      ]) {
        expect(
          () => LinuxSystemdNotificationUnit(
            scheduleKey: key,
            scheduledAtUtc: DateTime.utc(2026, 7, 28),
            executablePath: '/opt/borj',
          ),
          throwsArgumentError,
          reason: 'unsafe key must be rejected: $key',
        );
      }
    });

    test('rejects a non-UTC schedule', () {
      expect(
        () => LinuxSystemdNotificationUnit(
          scheduleKey: 'schedule-1',
          scheduledAtUtc: DateTime(2026, 7, 28),
          executablePath: '/opt/borj',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a relative executable path', () {
      expect(
        () => LinuxSystemdNotificationUnit(
          scheduleKey: 'schedule-1',
          scheduledAtUtc: DateTime.utc(2026, 7, 28),
          executablePath: 'borj',
        ),
        throwsArgumentError,
      );
    });

    test('rejects control characters in executable and arguments', () {
      expect(
        () => LinuxSystemdNotificationUnit(
          scheduleKey: 'schedule-1',
          scheduledAtUtc: DateTime.utc(2026, 7, 28),
          executablePath: '/opt/bor\nj',
        ),
        throwsArgumentError,
      );

      expect(
        () => LinuxSystemdNotificationUnit(
          scheduleKey: 'schedule-1',
          scheduledAtUtc: DateTime.utc(2026, 7, 28),
          executablePath: '/opt/borj',
          arguments: const <String>['safe', 'bad\u0000argument'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('LinuxSystemdUnitNames', () {
    test('is deterministic for the same schedule key', () {
      final first = LinuxSystemdUnitNames.forScheduleKey(
        'task:alpha/notification-1',
      );
      final second = LinuxSystemdUnitNames.forScheduleKey(
        'task:alpha/notification-1',
      );

      expect(first, second);
      expect(first.serviceFileName, second.serviceFileName);
      expect(first.timerFileName, second.timerFileName);
    });

    test('produces different names for different schedule keys', () {
      final first = LinuxSystemdUnitNames.forScheduleKey('schedule-1');
      final second = LinuxSystemdUnitNames.forScheduleKey('schedule-2');

      expect(first.baseName, isNot(second.baseName));
    });

    test('rejects an empty schedule key directly', () {
      expect(
        () => LinuxSystemdUnitNames.forScheduleKey(''),
        throwsArgumentError,
      );
    });

    test('produces systemd-safe bounded file names', () {
      final names = LinuxSystemdUnitNames.forScheduleKey(
        'unsafe:/ key with spaces?query#fragment',
      );

      expect(
        names.baseName,
        matches(RegExp(r'^borj-notification-[0-9a-f]{16}$')),
      );
      expect(names.serviceFileName, '${names.baseName}.service');
      expect(names.timerFileName, '${names.baseName}.timer');
      expect(names.serviceFileName.length, lessThan(100));
      expect(names.timerFileName.length, lessThan(100));
    });
  });

  group('LinuxSystemdUnitRenderer', () {
    const renderer = LinuxSystemdUnitRenderer();

    LinuxSystemdNotificationUnit buildUnit({
      String executablePath = '/opt/Borj/borj',
      List<String> arguments = const <String>[
        '--deliver-notification',
        'schedule-1',
      ],
    }) {
      return LinuxSystemdNotificationUnit(
        scheduleKey: 'schedule-1',
        scheduledAtUtc: DateTime.utc(2026, 7, 28, 18, 45, 6),
        executablePath: executablePath,
        arguments: arguments,
      );
    }

    test('renders matching service and timer file names', () {
      final rendered = renderer.render(buildUnit());
      final names = LinuxSystemdUnitNames.forScheduleKey('schedule-1');

      expect(rendered.serviceFileName, names.serviceFileName);
      expect(rendered.timerFileName, names.timerFileName);
    });

    test('renders a oneshot service without a shell', () {
      final rendered = renderer.render(buildUnit());

      expect(rendered.serviceContents, contains('[Service]\n'));
      expect(rendered.serviceContents, contains('Type=oneshot\n'));
      expect(rendered.serviceContents, contains('ExecStart='));
      expect(rendered.serviceContents, isNot(contains('/bin/sh')));
      expect(rendered.serviceContents, isNot(contains('sh -c')));
    });

    test('quotes executable paths and command arguments safely', () {
      final rendered = renderer.render(
        buildUnit(
          executablePath: r'/opt/Borj "App"\bin/$release%/borj',
          arguments: const <String>[
            '--title=Review "Today"',
            r'path\with\slashes',
            r'$HOME',
            '100%',
          ],
        ),
      );

      expect(
        rendered.serviceContents,
        contains(
          r'ExecStart="/opt/Borj \"App\"\\bin/$$release%%/'
          r'borj" "--title=Review \"Today\"" '
          r'"path\\with\\slashes" "$$HOME" "100%%"',
        ),
      );
    });

    test('renders an exact one-shot UTC calendar time', () {
      final rendered = renderer.render(buildUnit());

      expect(
        rendered.timerContents,
        contains('OnCalendar=2026-07-28 18:45:06 UTC\n'),
      );
      expect(rendered.timerContents, contains('AccuracySec=1s\n'));
      expect(rendered.timerContents, contains('RandomizedDelaySec=0\n'));
      expect(rendered.timerContents, contains('Persistent=true\n'));
    });

    test('points the timer to its matching service', () {
      final rendered = renderer.render(buildUnit());

      expect(
        rendered.timerContents,
        contains('Unit=${rendered.serviceFileName}\n'),
      );
    });

    test('installs the timer under the user timers target', () {
      final rendered = renderer.render(buildUnit());

      expect(rendered.timerContents, contains('[Install]\n'));
      expect(rendered.timerContents, contains('WantedBy=timers.target\n'));
    });

    test('renders deterministic content with one trailing newline', () {
      final first = renderer.render(buildUnit());
      final second = renderer.render(buildUnit());

      expect(first, second);
      expect(first.serviceContents.endsWith('\n'), isTrue);
      expect(first.timerContents.endsWith('\n'), isTrue);
      expect(first.serviceContents.endsWith('\n\n'), isFalse);
      expect(first.timerContents.endsWith('\n\n'), isFalse);
    });

    test('does not expose the raw schedule key in unit file names', () {
      final unit = LinuxSystemdNotificationUnit(
        scheduleKey: 'private-task-owner-id',
        scheduledAtUtc: DateTime.utc(2026, 7, 28),
        executablePath: '/opt/borj',
      );
      final rendered = renderer.render(unit);

      expect(
        rendered.serviceFileName,
        isNot(contains('private-task-owner-id')),
      );
      expect(rendered.timerFileName, isNot(contains('private-task-owner-id')));
    });
  });
}
