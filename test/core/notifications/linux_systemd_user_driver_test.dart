import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_timer_status_parser.dart';
import 'package:borj/core/notifications/linux_systemd_user_driver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_process_runner.dart';

void main() {
  group('LinuxSystemdUserDriver daemon reload', () {
    test('builds the exact hardened daemon-reload request', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final source = LinuxCancellationSource();
      final controlled = runner.enqueueControlled();

      final future = driver.reloadDaemon(cancellationToken: source.token);
      final invocation = await controlled.invocation;

      expect(invocation.cancellationToken, same(source.token));
      expect(invocation.request.executable, 'systemctl');
      expect(
        invocation.request.arguments,
        orderedEquals(<String>['--user', '--no-pager', 'daemon-reload']),
      );
      expect(
        invocation.request.environment,
        equals(const <String, String>{
          'LC_ALL': 'C',
          'LANG': 'C',
          'SYSTEMD_COLORS': '0',
          'SYSTEMD_PAGER': 'cat',
          'SYSTEMD_PAGERSECURE': '1',
        }),
      );
      expect(invocation.request.includeParentEnvironment, isTrue);
      expect(invocation.request.timeout, const Duration(seconds: 15));
      expect(
        invocation.request.terminationGracePeriod,
        const Duration(seconds: 2),
      );
      expect(invocation.request.stdoutLimitBytes, 256 * 1024);
      expect(invocation.request.stderrLimitBytes, 256 * 1024);

      controlled.complete(
        _resultFor(invocation.request.executable, invocation.request.arguments),
      );

      await future;
    });

    test('supports an explicit executable and process limits', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(
        processRunner: runner,
        executable: '/usr/bin/systemctl',
        timeout: const Duration(seconds: 9),
        terminationGracePeriod: const Duration(milliseconds: 750),
        stdoutLimitBytes: 8 * 1024,
        stderrLimitBytes: 16 * 1024,
        includeParentEnvironment: false,
      );
      final controlled = runner.enqueueControlled();

      final future = driver.reloadDaemon();
      final invocation = await controlled.invocation;

      expect(invocation.request.executable, '/usr/bin/systemctl');
      expect(invocation.request.timeout, const Duration(seconds: 9));
      expect(
        invocation.request.terminationGracePeriod,
        const Duration(milliseconds: 750),
      );
      expect(invocation.request.stdoutLimitBytes, 8 * 1024);
      expect(invocation.request.stderrLimitBytes, 16 * 1024);
      expect(invocation.request.includeParentEnvironment, isFalse);

      controlled.complete(
        _resultFor(invocation.request.executable, invocation.request.arguments),
      );

      await future;
    });

    test(
      'throws a typed command error for nonzero daemon-reload exit',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final result = _resultFor(
          'systemctl',
          const <String>['--user', '--no-pager', 'daemon-reload'],
          exitCode: 1,
          stderr: 'reload failed',
        );

        runner.enqueueResult(result);

        await expectLater(
          driver.reloadDaemon(),
          throwsA(
            isA<LinuxSystemdCommandException>()
                .having(
                  (error) => error.operation,
                  'operation',
                  LinuxSystemdCommandOperation.daemonReload,
                )
                .having((error) => error.result, 'result', same(result))
                .having(
                  (error) => error.toString(),
                  'safe diagnostics',
                  isNot(contains('TOP_SECRET')),
                ),
          ),
        );
      },
    );

    test('propagates runner lifecycle failures unchanged', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final failure = StateError('runner failed');
      final stackTrace = StackTrace.current;

      runner.enqueueFailure(failure, stackTrace);

      await expectLater(driver.reloadDaemon(), throwsA(same(failure)));
    });
  });

  group('LinuxSystemdUserDriver status', () {
    final name = LinuxSystemdTimerName.parse(
      'borj-notification-0123456789abcdef.timer',
    );

    test('builds one exact machine-readable show request', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final source = LinuxCancellationSource();
      final controlled = runner.enqueueControlled();

      final future = driver.status(name, cancellationToken: source.token);
      final invocation = await controlled.invocation;

      expect(invocation.cancellationToken, same(source.token));
      expect(invocation.request.executable, 'systemctl');
      expect(
        invocation.request.arguments,
        orderedEquals(<String>[
          '--user',
          '--no-pager',
          'show',
          name.value,
          '--property=Id,LoadState,ActiveState,SubState,UnitFileState,Result',
        ]),
      );
      expect(invocation.request.environment['SYSTEMD_COLORS'], '0');
      expect(invocation.request.environment['SYSTEMD_PAGER'], 'cat');

      controlled.complete(
        _resultFor(
          invocation.request.executable,
          invocation.request.arguments,
          stdout: _healthyStatusOutput(name),
        ),
      );

      final status = await future;
      expect(status.name, name);
      expect(status.isHealthy, isTrue);
    });

    test('parses disabled inactive status without guessing', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);

      runner.enqueueResult(
        _resultFor(
          'systemctl',
          _statusArguments(name),
          stdout: _statusOutput(
            name,
            activeState: 'inactive',
            subState: 'dead',
            unitFileState: 'disabled',
          ),
        ),
      );

      final status = await driver.status(name);

      expect(status.isInstalled, isTrue);
      expect(status.isEnabled, isFalse);
      expect(status.isActive, isFalse);
      expect(status.isHealthy, isFalse);
    });

    test('throws a typed command error for nonzero status exit', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final result = _resultFor(
        'systemctl',
        _statusArguments(name),
        exitCode: 4,
        stderr: 'Unit not found',
      );

      runner.enqueueResult(result);

      await expectLater(
        driver.status(name),
        throwsA(
          isA<LinuxSystemdCommandException>()
              .having(
                (error) => error.operation,
                'operation',
                LinuxSystemdCommandOperation.status,
              )
              .having((error) => error.timerName, 'timerName', name)
              .having((error) => error.result, 'result', same(result)),
        ),
      );
    });

    test('rejects truncated status output before parsing', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final output = _boundedOutput(
        _healthyStatusOutput(name),
        truncated: true,
        droppedBytes: 12,
      );
      final result = _resultFor(
        'systemctl',
        _statusArguments(name),
        stdoutOutput: output,
      );

      runner.enqueueResult(result);

      await expectLater(
        driver.status(name),
        throwsA(
          isA<LinuxSystemdStatusOutputException>()
              .having(
                (error) => error.failure,
                'failure',
                LinuxSystemdStatusOutputFailure.truncated,
              )
              .having((error) => error.timerName, 'timerName', name)
              .having((error) => error.result, 'result', same(result)),
        ),
      );
    });

    test('rejects malformed UTF-8 status output before parsing', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final result = _resultFor(
        'systemctl',
        _statusArguments(name),
        stdoutOutput: _boundedOutput(
          _healthyStatusOutput(name),
          malformedUtf8: true,
        ),
      );

      runner.enqueueResult(result);

      await expectLater(
        driver.status(name),
        throwsA(
          isA<LinuxSystemdStatusOutputException>().having(
            (error) => error.failure,
            'failure',
            LinuxSystemdStatusOutputFailure.malformedUtf8,
          ),
        ),
      );
    });

    test('propagates strict parser failures unchanged', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);

      runner.enqueueResult(
        _resultFor(
          'systemctl',
          _statusArguments(name),
          stdout: '${_healthyStatusOutput(name)}Unknown=value\n',
        ),
      );

      await expectLater(
        driver.status(name),
        throwsA(isA<LinuxSystemdTimerStatusParseException>()),
      );
    });
  });
}

List<String> _statusArguments(LinuxSystemdTimerName name) {
  return <String>[
    '--user',
    '--no-pager',
    'show',
    name.value,
    '--property=Id,LoadState,ActiveState,SubState,UnitFileState,Result',
  ];
}

LinuxProcessResult _resultFor(
  String executable,
  List<String> arguments, {
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
  LinuxBoundedOutput? stdoutOutput,
}) {
  return LinuxProcessResult(
    executable: executable,
    arguments: arguments,
    pid: 42,
    exitCode: exitCode,
    duration: const Duration(milliseconds: 5),
    stdout: stdoutOutput ?? _boundedOutput(stdout),
    stderr: _boundedOutput(stderr),
  );
}

LinuxBoundedOutput _boundedOutput(
  String text, {
  bool truncated = false,
  bool malformedUtf8 = false,
  int droppedBytes = 0,
}) {
  final retainedBytes = text.codeUnits.length;

  return LinuxBoundedOutput(
    text: text,
    totalBytes: retainedBytes + droppedBytes,
    retainedBytes: retainedBytes,
    droppedBytes: droppedBytes,
    truncated: truncated,
    malformedUtf8: malformedUtf8,
  );
}

String _healthyStatusOutput(LinuxSystemdTimerName name) {
  return _statusOutput(name);
}

String _statusOutput(
  LinuxSystemdTimerName name, {
  String loadState = 'loaded',
  String activeState = 'active',
  String subState = 'waiting',
  String unitFileState = 'enabled',
  String result = 'success',
}) {
  return <String>[
    'Id=${name.value}',
    'LoadState=$loadState',
    'ActiveState=$activeState',
    'SubState=$subState',
    'UnitFileState=$unitFileState',
    'Result=$result',
    '',
  ].join('\n');
}
