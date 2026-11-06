import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_systemd_mutation.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_timer_status_parser.dart';
import 'package:borj/core/notifications/linux_systemd_user_driver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_process_runner.dart';

void main() {
  group('Task 10.3 final systemd checkpoint', () {
    final timer = LinuxSystemdTimerName.parse(
      'borj-notification-0123456789abcdef.timer',
    );

    test('completes reload, enable, status, and disable lifecycle', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);

      final reload = runner.enqueueControlled();
      final reloadFuture = driver.reloadDaemon();
      final reloadInvocation = await reload.invocation;

      expect(
        reloadInvocation.request.arguments,
        orderedEquals(<String>['--user', '--no-pager', 'daemon-reload']),
      );
      _expectHardenedRequest(reloadInvocation.request.environment);
      reload.complete(_result(reloadInvocation.request.arguments));
      await reloadFuture;

      final enable = runner.enqueueControlled();
      final enableStatus = runner.enqueueControlled();
      final enableFuture = driver.enableAndStart(timer);
      final enableInvocation = await enable.invocation;

      expect(
        enableInvocation.request.arguments,
        orderedEquals(<String>[
          '--user',
          '--no-pager',
          'enable',
          '--now',
          timer.value,
        ]),
      );
      _expectHardenedRequest(enableInvocation.request.environment);
      enable.complete(_result(enableInvocation.request.arguments));

      final enableStatusInvocation = await enableStatus.invocation;
      expect(
        enableStatusInvocation.request.arguments,
        orderedEquals(_statusArguments(timer)),
      );
      enableStatus.complete(_statusResult(timer));

      final enabledStatus = await enableFuture;
      expect(enabledStatus.isHealthy, isTrue);

      final statusCall = runner.enqueueControlled();
      final statusFuture = driver.status(timer);
      final statusInvocation = await statusCall.invocation;

      expect(
        statusInvocation.request.arguments,
        orderedEquals(_statusArguments(timer)),
      );
      statusCall.complete(_statusResult(timer));

      final directStatus = await statusFuture;
      expect(directStatus.name, timer);
      expect(directStatus.isEnabled, isTrue);
      expect(directStatus.isActive, isTrue);

      final disable = runner.enqueueControlled();
      final disableStatus = runner.enqueueControlled();
      final disableFuture = driver.disableAndStop(timer);
      final disableInvocation = await disable.invocation;

      expect(
        disableInvocation.request.arguments,
        orderedEquals(<String>[
          '--user',
          '--no-pager',
          'disable',
          '--now',
          timer.value,
        ]),
      );
      _expectHardenedRequest(disableInvocation.request.environment);
      disable.complete(_result(disableInvocation.request.arguments));

      final disableStatusInvocation = await disableStatus.invocation;
      expect(
        disableStatusInvocation.request.arguments,
        orderedEquals(_statusArguments(timer)),
      );
      disableStatus.complete(
        _statusResult(
          timer,
          activeState: 'inactive',
          subState: 'dead',
          unitFileState: 'disabled',
        ),
      );

      final disabledStatus = await disableFuture;
      expect(disabledStatus.isInstalled, isTrue);
      expect(disabledStatus.isEnabled, isFalse);
      expect(disabledStatus.isActive, isFalse);
      expect(disabledStatus.isHealthy, isFalse);
      expect(runner.pendingResponseCount, 0);
    });

    test(
      'propagates one cancellation token through mutation and status',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final source = LinuxCancellationSource();
        final command = runner.enqueueControlled();
        final status = runner.enqueueControlled();

        final future = driver.enableAndStart(
          timer,
          cancellationToken: source.token,
        );

        final commandInvocation = await command.invocation;
        expect(commandInvocation.cancellationToken, same(source.token));
        command.complete(_result(commandInvocation.request.arguments));

        final statusInvocation = await status.invocation;
        expect(statusInvocation.cancellationToken, same(source.token));
        status.complete(_statusResult(timer));

        expect((await future).isHealthy, isTrue);
      },
    );

    test('keeps command diagnostics typed without leaking stderr', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final result = _result(
        <String>['--user', '--no-pager', 'enable', '--now', timer.value],
        exitCode: 1,
        stderr: 'TOP_SECRET',
      );

      runner.enqueueResult(result);

      await expectLater(
        driver.enableAndStart(timer),
        throwsA(
          isA<LinuxSystemdMutationException>()
              .having(
                (error) => error.failure,
                'failure',
                LinuxSystemdMutationFailure.commandFailed,
              )
              .having((error) => error.statusChecks, 'statusChecks', 0)
              .having(
                (error) => error.toString(),
                'safe diagnostics',
                isNot(contains('TOP_SECRET')),
              ),
        ),
      );

      expect(runner.pendingResponseCount, 0);
    });

    test(
      'fails closed when machine-readable status gains a property',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final statusText = '${_statusText(timer)}FutureProperty=value\n';

        runner.enqueueResult(
          _result(_statusArguments(timer), stdout: statusText),
        );

        await expectLater(
          driver.status(timer),
          throwsA(
            isA<LinuxSystemdTimerStatusParseException>().having(
              (error) => error.failure,
              'failure',
              LinuxSystemdTimerStatusParseFailure.unknownProperty,
            ),
          ),
        );
      },
    );
  });
}

void _expectHardenedRequest(Map<String, String> environment) {
  expect(environment, containsPair('LC_ALL', 'C'));
  expect(environment, containsPair('LANG', 'C'));
  expect(environment, containsPair('SYSTEMD_COLORS', '0'));
  expect(environment, containsPair('SYSTEMD_PAGER', 'cat'));
  expect(environment, containsPair('SYSTEMD_PAGERSECURE', '1'));
}

List<String> _statusArguments(LinuxSystemdTimerName timer) {
  return <String>[
    '--user',
    '--no-pager',
    'show',
    timer.value,
    '--property=Id,LoadState,ActiveState,SubState,UnitFileState,Result',
  ];
}

LinuxProcessResult _statusResult(
  LinuxSystemdTimerName timer, {
  String activeState = 'active',
  String subState = 'waiting',
  String unitFileState = 'enabled',
}) {
  return _result(
    _statusArguments(timer),
    stdout: _statusText(
      timer,
      activeState: activeState,
      subState: subState,
      unitFileState: unitFileState,
    ),
  );
}

String _statusText(
  LinuxSystemdTimerName timer, {
  String activeState = 'active',
  String subState = 'waiting',
  String unitFileState = 'enabled',
}) {
  return <String>[
    'Id=${timer.value}',
    'LoadState=loaded',
    'ActiveState=$activeState',
    'SubState=$subState',
    'UnitFileState=$unitFileState',
    'Result=success',
    '',
  ].join('\n');
}

LinuxProcessResult _result(
  List<String> arguments, {
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
}) {
  return LinuxProcessResult(
    executable: 'systemctl',
    arguments: arguments,
    pid: 103,
    exitCode: exitCode,
    duration: const Duration(milliseconds: 8),
    stdout: _output(stdout),
    stderr: _output(stderr),
  );
}

LinuxBoundedOutput _output(String text) {
  final byteCount = text.codeUnits.length;

  return LinuxBoundedOutput(
    text: text,
    totalBytes: byteCount,
    retainedBytes: byteCount,
    droppedBytes: 0,
    truncated: false,
    malformedUtf8: false,
  );
}
