import 'dart:async';

import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_process_exception.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_systemd_mutation.dart';
import 'package:borj/core/notifications/linux_systemd_timer_name.dart';
import 'package:borj/core/notifications/linux_systemd_user_driver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_process_runner.dart';

void main() {
  group('LinuxSystemdUserDriver mutations', () {
    final timer = _timer('0123456789abcdef');

    test(
      'enableAndStart executes the exact command and verifies status',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final command = runner.enqueueControlled();
        final verification = runner.enqueueControlled();

        final future = driver.enableAndStart(timer);

        final commandInvocation = await command.invocation;
        expect(
          commandInvocation.request.arguments,
          orderedEquals(<String>[
            '--user',
            '--no-pager',
            'enable',
            '--now',
            timer.value,
          ]),
        );

        command.complete(_resultFor(commandInvocation.request.arguments));

        final statusInvocation = await verification.invocation;
        expect(
          statusInvocation.request.arguments,
          orderedEquals(_statusArguments(timer)),
        );

        verification.complete(_statusResult(timer));

        final status = await future;
        expect(status.isInstalled, isTrue);
        expect(status.isEnabled, isTrue);
        expect(status.isActive, isTrue);
      },
    );

    test(
      'disableAndStop executes the exact command and verifies status',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final command = runner.enqueueControlled();
        final verification = runner.enqueueControlled();

        final future = driver.disableAndStop(timer);

        final commandInvocation = await command.invocation;
        expect(
          commandInvocation.request.arguments,
          orderedEquals(<String>[
            '--user',
            '--no-pager',
            'disable',
            '--now',
            timer.value,
          ]),
        );

        command.complete(_resultFor(commandInvocation.request.arguments));

        final statusInvocation = await verification.invocation;
        verification.complete(
          _statusResult(
            timer,
            activeState: 'inactive',
            subState: 'dead',
            unitFileState: 'disabled',
          ),
        );

        final status = await future;
        expect(statusInvocation.request.arguments, _statusArguments(timer));
        expect(status.isInstalled, isTrue);
        expect(status.isEnabled, isFalse);
        expect(status.isActive, isFalse);
      },
    );

    test('nonzero mutation exit is definitive and skips status', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final result = _resultFor(
        _enableArguments(timer),
        exitCode: 1,
        stderr: 'enable failed',
      );

      runner.enqueueResult(result);

      await expectLater(
        driver.enableAndStart(timer),
        throwsA(
          isA<LinuxSystemdMutationException>()
              .having(
                (error) => error.operation,
                'operation',
                LinuxSystemdMutationOperation.enableAndStart,
              )
              .having(
                (error) => error.failure,
                'failure',
                LinuxSystemdMutationFailure.commandFailed,
              )
              .having(
                (error) => error.commandResult,
                'commandResult',
                same(result),
              )
              .having((error) => error.statusChecks, 'statusChecks', 0),
        ),
      );
    });

    test(
      'a successful command reconciles one mismatched postcondition',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);

        runner.enqueueResult(_resultFor(_enableArguments(timer)));
        runner.enqueueResult(
          _statusResult(
            timer,
            activeState: 'inactive',
            subState: 'dead',
            unitFileState: 'disabled',
          ),
        );
        runner.enqueueResult(_statusResult(timer));

        final status = await driver.enableAndStart(timer);

        expect(status.isEnabled, isTrue);
        expect(status.isActive, isTrue);
        expect(runner.pendingResponseCount, 0);
      },
    );

    test('fails after exactly one postcondition reconciliation', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final mismatched = _statusResult(
        timer,
        activeState: 'inactive',
        subState: 'dead',
        unitFileState: 'disabled',
      );

      runner.enqueueResult(_resultFor(_enableArguments(timer)));
      runner.enqueueResult(mismatched);
      runner.enqueueResult(mismatched);

      await expectLater(
        driver.enableAndStart(timer),
        throwsA(
          isA<LinuxSystemdMutationException>()
              .having(
                (error) => error.failure,
                'failure',
                LinuxSystemdMutationFailure.postconditionFailed,
              )
              .having((error) => error.statusChecks, 'statusChecks', 2)
              .having(
                (error) => error.observedStatus?.isEnabled,
                'observed enabled',
                isFalse,
              ),
        ),
      );

      expect(runner.pendingResponseCount, 0);
    });

    test(
      'timeout reconciles once and succeeds when desired state exists',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final timeout = _timeoutFailure(_enableArguments(timer));

        runner.enqueueFailure(timeout, StackTrace.current);
        runner.enqueueResult(_statusResult(timer));

        final status = await driver.enableAndStart(timer);

        expect(status.isEnabled, isTrue);
        expect(status.isActive, isTrue);
        expect(runner.pendingResponseCount, 0);
      },
    );

    test(
      'timeout mismatch reports an ambiguous outcome after one status',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final timeout = _timeoutFailure(_enableArguments(timer));

        runner.enqueueFailure(timeout, StackTrace.current);
        runner.enqueueResult(
          _statusResult(
            timer,
            activeState: 'inactive',
            subState: 'dead',
            unitFileState: 'disabled',
          ),
        );

        await expectLater(
          driver.enableAndStart(timer),
          throwsA(
            isA<LinuxSystemdMutationException>()
                .having(
                  (error) => error.failure,
                  'failure',
                  LinuxSystemdMutationFailure.ambiguousOutcome,
                )
                .having(
                  (error) => error.commandError,
                  'commandError',
                  same(timeout),
                )
                .having((error) => error.statusChecks, 'statusChecks', 1),
          ),
        );
      },
    );

    test(
      'explicit cancellation remains cancellation without reconciliation',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final cancellation = _cancellationFailure(_enableArguments(timer));

        runner.enqueueFailure(cancellation, StackTrace.current);

        await expectLater(
          driver.enableAndStart(timer),
          throwsA(same(cancellation)),
        );

        expect(runner.pendingResponseCount, 0);
      },
    );

    test('start failures remain definitive without reconciliation', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final failure = LinuxProcessStartException(
        executable: 'systemctl',
        arguments: _enableArguments(timer),
        cause: StateError('spawn failed'),
        stackTrace: StackTrace.current,
      );

      runner.enqueueFailure(failure, StackTrace.current);

      await expectLater(driver.enableAndStart(timer), throwsA(same(failure)));
    });

    test('status failure during ambiguous reconciliation is typed', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final timeout = _timeoutFailure(_enableArguments(timer));
      final statusFailure = StateError('status failed');

      runner.enqueueFailure(timeout, StackTrace.current);
      runner.enqueueFailure(statusFailure, StackTrace.current);

      await expectLater(
        driver.enableAndStart(timer),
        throwsA(
          isA<LinuxSystemdMutationException>()
              .having(
                (error) => error.failure,
                'failure',
                LinuxSystemdMutationFailure.reconciliationFailed,
              )
              .having(
                (error) => error.commandError,
                'commandError',
                same(timeout),
              )
              .having(
                (error) => error.reconciliationError,
                'reconciliationError',
                same(statusFailure),
              )
              .having((error) => error.statusChecks, 'statusChecks', 1),
        ),
      );
    });
  });

  group('LinuxSystemdUserDriver lock integration', () {
    test(
      'same timer mutations remain FIFO through postcondition status',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final timer = _timer('aaaaaaaaaaaaaaaa');
        final firstCommand = runner.enqueueControlled();
        final firstStatus = runner.enqueueControlled();
        final secondCommand = runner.enqueueControlled();
        final secondStatus = runner.enqueueControlled();
        var secondStarted = false;

        unawaited(
          secondCommand.invocation.then((_) {
            secondStarted = true;
          }),
        );

        final firstFuture = driver.enableAndStart(timer);
        final secondFuture = driver.disableAndStop(timer);

        final firstInvocation = await firstCommand.invocation;
        await Future<void>.delayed(Duration.zero);
        expect(secondStarted, isFalse);

        firstCommand.complete(_resultFor(firstInvocation.request.arguments));
        final firstStatusInvocation = await firstStatus.invocation;
        firstStatus.complete(_statusResult(timer));

        await firstFuture;
        final secondInvocation = await secondCommand.invocation;
        expect(secondStarted, isTrue);
        expect(secondInvocation.request.arguments, _disableArguments(timer));

        secondCommand.complete(_resultFor(secondInvocation.request.arguments));
        await secondStatus.invocation;
        secondStatus.complete(
          _statusResult(
            timer,
            activeState: 'inactive',
            subState: 'dead',
            unitFileState: 'disabled',
          ),
        );

        await secondFuture;
        expect(
          firstStatusInvocation.request.arguments,
          _statusArguments(timer),
        );
      },
    );

    test('different timer mutations can execute concurrently', () async {
      final runner = FakeLinuxProcessRunner();
      final driver = LinuxSystemdUserDriver(processRunner: runner);
      final firstTimer = _timer('aaaaaaaaaaaaaaaa');
      final secondTimer = _timer('bbbbbbbbbbbbbbbb');
      final firstCommand = runner.enqueueControlled();
      final secondCommand = runner.enqueueControlled();
      final firstStatus = runner.enqueueControlled();
      final secondStatus = runner.enqueueControlled();

      final firstFuture = driver.enableAndStart(firstTimer);
      final secondFuture = driver.enableAndStart(secondTimer);

      final commandInvocations = await Future.wait(
        <Future<ControlledLinuxProcessInvocation>>[
          firstCommand.invocation,
          secondCommand.invocation,
        ],
      );

      expect(
        commandInvocations.map((item) => item.request.arguments.last),
        unorderedEquals(<String>[firstTimer.value, secondTimer.value]),
      );

      firstCommand.complete(
        _resultFor(commandInvocations[0].request.arguments),
      );
      secondCommand.complete(
        _resultFor(commandInvocations[1].request.arguments),
      );

      final firstStatusInvocation = await firstStatus.invocation;
      final firstStatusName = LinuxSystemdTimerName.parse(
        firstStatusInvocation.request.arguments[3],
      );
      firstStatus.complete(_statusResult(firstStatusName));

      final secondStatusInvocation = await secondStatus.invocation;
      final secondStatusName = LinuxSystemdTimerName.parse(
        secondStatusInvocation.request.arguments[3],
      );
      secondStatus.complete(_statusResult(secondStatusName));

      await Future.wait(<Future<Object?>>[firstFuture, secondFuture]);
    });

    test(
      'queued daemon reload blocks later unit reads until it completes',
      () async {
        final runner = FakeLinuxProcessRunner();
        final driver = LinuxSystemdUserDriver(processRunner: runner);
        final firstTimer = _timer('cccccccccccccccc');
        final secondTimer = _timer('dddddddddddddddd');
        final firstStatus = runner.enqueueControlled();
        final reload = runner.enqueueControlled();
        final lateStatus = runner.enqueueControlled();
        var reloadStarted = false;
        var lateStatusStarted = false;

        unawaited(reload.invocation.then((_) => reloadStarted = true));
        unawaited(lateStatus.invocation.then((_) => lateStatusStarted = true));

        final firstFuture = driver.status(firstTimer);
        final reloadFuture = driver.reloadDaemon();
        final lateFuture = driver.status(secondTimer);

        await firstStatus.invocation;
        await Future<void>.delayed(Duration.zero);
        expect(reloadStarted, isFalse);
        expect(lateStatusStarted, isFalse);

        firstStatus.complete(_statusResult(firstTimer));
        await firstFuture;

        final reloadInvocation = await reload.invocation;
        expect(reloadStarted, isTrue);
        expect(lateStatusStarted, isFalse);

        reload.complete(_resultFor(reloadInvocation.request.arguments));
        await reloadFuture;

        await lateStatus.invocation;
        expect(lateStatusStarted, isTrue);
        lateStatus.complete(_statusResult(secondTimer));
        await lateFuture;
      },
    );
  });
}

LinuxSystemdTimerName _timer(String identityHex) {
  return LinuxSystemdTimerName.parse('borj-notification-$identityHex.timer');
}

List<String> _enableArguments(LinuxSystemdTimerName timer) {
  return <String>['--user', '--no-pager', 'enable', '--now', timer.value];
}

List<String> _disableArguments(LinuxSystemdTimerName timer) {
  return <String>['--user', '--no-pager', 'disable', '--now', timer.value];
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

LinuxProcessResult _resultFor(
  List<String> arguments, {
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
}) {
  return LinuxProcessResult(
    executable: 'systemctl',
    arguments: arguments,
    pid: 77,
    exitCode: exitCode,
    duration: const Duration(milliseconds: 5),
    stdout: _output(stdout),
    stderr: _output(stderr),
  );
}

LinuxProcessResult _statusResult(
  LinuxSystemdTimerName timer, {
  String loadState = 'loaded',
  String activeState = 'active',
  String subState = 'waiting',
  String unitFileState = 'enabled',
  String result = 'success',
}) {
  final output = <String>[
    'Id=${timer.value}',
    'LoadState=$loadState',
    'ActiveState=$activeState',
    'SubState=$subState',
    'UnitFileState=$unitFileState',
    'Result=$result',
    '',
  ].join('\n');

  return _resultFor(_statusArguments(timer), stdout: output);
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

LinuxProcessTimeoutException _timeoutFailure(List<String> arguments) {
  return LinuxProcessTimeoutException(
    executable: 'systemctl',
    arguments: arguments,
    pid: 77,
    duration: const Duration(seconds: 17),
    stdout: _output(''),
    stderr: _output(''),
    timeout: const Duration(seconds: 15),
    terminationGracePeriod: const Duration(seconds: 2),
    sigtermAttempted: true,
    sigtermDelivered: true,
    sigkillAttempted: true,
    sigkillDelivered: true,
  );
}

LinuxProcessCancellationException _cancellationFailure(List<String> arguments) {
  return LinuxProcessCancellationException(
    executable: 'systemctl',
    arguments: arguments,
    pid: 77,
    duration: const Duration(milliseconds: 50),
    stdout: _output(''),
    stderr: _output(''),
    terminationGracePeriod: const Duration(seconds: 2),
    sigtermAttempted: true,
    sigtermDelivered: true,
    sigkillAttempted: false,
    sigkillDelivered: false,
  );
}
