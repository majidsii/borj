import 'dart:async';
import 'dart:convert';

import 'package:borj/core/notifications/dart_io_linux_process_runner.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_exception.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_started_process.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_started_process.dart';

void main() {
  group('DartIoLinuxProcessRunner normal completion', () {
    test(
      'starts the exact request and returns complete process metadata',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 4242);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);
        final request = _request();

        starter.enqueueProcess(process);

        final future = runner.run(request);
        await Future.wait<void>(<Future<void>>[
          process.stdoutListened,
          process.stderrListened,
        ]);

        process.addStdout(utf8.encode('hello stdout'));
        process.addStderr(utf8.encode('hello stderr'));
        await process.closeStdout();
        await process.closeStderr();
        expect(process.completeExit(7), isTrue);

        final result = await future;

        expect(starter.requests, hasLength(1));
        expect(starter.requests.single, same(request));
        expect(result.executable, request.executable);
        expect(result.arguments, request.arguments);
        expect(result.pid, 4242);
        expect(result.exitCode, 7);
        expect(
          result.duration.compareTo(Duration.zero),
          greaterThanOrEqualTo(0),
        );
        expect(result.stdout.text, 'hello stdout');
        expect(result.stderr.text, 'hello stderr');
        expect(process.signals, isEmpty);
      },
    );

    test(
      'subscribes to stdout and stderr concurrently before either closes',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 7);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);

        starter.enqueueProcess(process);
        final future = runner.run(_request());

        await Future.wait<void>(<Future<void>>[
          process.stdoutListened.timeout(const Duration(seconds: 1)),
          process.stderrListened.timeout(const Duration(seconds: 1)),
        ]);

        process.addStdout(utf8.encode('out'));
        process.addStderr(utf8.encode('err'));
        process.completeExit(0);
        await Future.wait<void>(<Future<void>>[
          process.closeStdout(),
          process.closeStderr(),
        ]);

        await expectLater(future, completes);
      },
    );

    test(
      'captures stdout and stderr with independent bounded collectors',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 8);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);
        final request = _request(
          stdoutLimitBytes: 2048,
          stderrLimitBytes: 2048,
        );

        starter.enqueueProcess(process);
        final future = runner.run(request);

        await Future.wait<void>(<Future<void>>[
          process.stdoutListened,
          process.stderrListened,
        ]);

        final stdoutBytes = List<int>.generate(
          2050,
          (index) => 65 + (index % 26),
          growable: false,
        );
        final stderrBytes = List<int>.generate(
          2050,
          (index) => 48 + (index % 10),
          growable: false,
        );

        process.addStdout(stdoutBytes);
        process.addStderr(stderrBytes);
        process.completeExit(0);
        await Future.wait<void>(<Future<void>>[
          process.closeStdout(),
          process.closeStderr(),
        ]);

        final result = await future;

        expect(result.stdout.totalBytes, 2050);
        expect(result.stdout.retainedBytes, 2048);
        expect(result.stdout.droppedBytes, 2);
        expect(result.stdout.truncated, isTrue);

        expect(result.stderr.totalBytes, 2050);
        expect(result.stderr.retainedBytes, 2048);
        expect(result.stderr.droppedBytes, 2);
        expect(result.stderr.truncated, isTrue);
      },
    );

    test('waits for exit code and both streams before completing', () async {
      final starter = FakeLinuxProcessStarter();
      final process = ControllableLinuxStartedProcess(pid: 9);
      final runner = DartIoLinuxProcessRunner(processStarter: starter);
      var completed = false;

      starter.enqueueProcess(process);
      final future = runner.run(_request()).then((result) {
        completed = true;
        return result;
      });

      await Future.wait<void>(<Future<void>>[
        process.stdoutListened,
        process.stderrListened,
      ]);

      expect(process.completeExit(0), isTrue);
      await process.closeStdout();
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      await process.closeStderr();
      await future;
      expect(completed, isTrue);
    });

    test('wraps process start failures with safe command context', () async {
      final starter = FakeLinuxProcessStarter();
      final runner = DartIoLinuxProcessRunner(processStarter: starter);
      final request = _request();
      final cause = StateError('start failed');
      final stackTrace = StackTrace.current;

      starter.enqueueFailure(cause, stackTrace);

      await expectLater(
        runner.run(request),
        throwsA(
          isA<LinuxProcessStartException>()
              .having(
                (error) => error.executable,
                'executable',
                request.executable,
              )
              .having(
                (error) => error.arguments,
                'arguments',
                request.arguments,
              )
              .having((error) => error.cause, 'cause', same(cause))
              .having(
                (error) => error.stackTrace,
                'stackTrace',
                same(stackTrace),
              )
              .having(
                (error) => error.toString(),
                'safe diagnostics',
                isNot(contains('TOP_SECRET')),
              ),
        ),
      );
    });

    test(
      'maps stdout errors after draining stderr and observing process exit',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 10);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);
        final cause = StateError('stdout failed');
        final stackTrace = StackTrace.current;

        starter.enqueueProcess(process);
        final future = runner.run(_request());
        final expectation = expectLater(
          future,
          throwsA(
            isA<LinuxProcessStreamException>()
                .having(
                  (error) => error.stream,
                  'stream',
                  LinuxProcessStreamKind.stdout,
                )
                .having((error) => error.pid, 'pid', 10)
                .having((error) => error.cause, 'cause', same(cause))
                .having(
                  (error) => error.stderr?.text,
                  'drained stderr',
                  'still drained',
                ),
          ),
        );

        await Future.wait<void>(<Future<void>>[
          process.stdoutListened,
          process.stderrListened,
        ]);

        process.addStdoutError(cause, stackTrace);
        await process.closeStdout();
        process.addStderr(utf8.encode('still drained'));
        await process.closeStderr();
        process.completeExit(1);

        await expectation;
        expect(process.signals, isEmpty);
      },
    );

    test('maps stderr errors with the matching stream kind', () async {
      final starter = FakeLinuxProcessStarter();
      final process = ControllableLinuxStartedProcess(pid: 11);
      final runner = DartIoLinuxProcessRunner(processStarter: starter);
      final cause = StateError('stderr failed');
      final stackTrace = StackTrace.current;

      starter.enqueueProcess(process);
      final future = runner.run(_request());
      final expectation = expectLater(
        future,
        throwsA(
          isA<LinuxProcessStreamException>()
              .having(
                (error) => error.stream,
                'stream',
                LinuxProcessStreamKind.stderr,
              )
              .having((error) => error.cause, 'cause', same(cause)),
        ),
      );

      await Future.wait<void>(<Future<void>>[
        process.stdoutListened,
        process.stderrListened,
      ]);

      process.addStdout(utf8.encode('still drained'));
      await process.closeStdout();
      process.addStderrError(cause, stackTrace);
      await process.closeStderr();
      process.completeExit(2);

      await expectation;
      expect(process.signals, isEmpty);
    });
  });

  group('DartIoLinuxProcessRunner termination', () {
    test('cancellation before spawn prevents process execution', () async {
      final starter = FakeLinuxProcessStarter();
      final process = ControllableLinuxStartedProcess(pid: 20);
      final runner = DartIoLinuxProcessRunner(processStarter: starter);
      final source = LinuxCancellationSource();

      starter.enqueueProcess(process);
      expect(source.cancel(), isTrue);

      await expectLater(
        runner.run(_terminationRequest(), cancellationToken: source.token),
        throwsA(
          isA<LinuxProcessCancellationException>()
              .having((error) => error.pid, 'pid', isNull)
              .having(
                (error) => error.sigtermAttempted,
                'sigtermAttempted',
                isFalse,
              )
              .having(
                (error) => error.sigkillAttempted,
                'sigkillAttempted',
                isFalse,
              ),
        ),
      );

      expect(starter.requests, isEmpty);
      expect(starter.pendingOutcomeCount, 1);
      expect(process.signals, isEmpty);
    });

    test(
      'timeout sends SIGTERM and skips SIGKILL when the process exits',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 21);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);

        process.killHandler = (signal) {
          if (signal == LinuxProcessSignal.sigterm) {
            unawaited(process.finish(exitCode: 143));
          }
        };
        starter.enqueueProcess(process);

        final fallback = _fallbackFinish(process);
        try {
          await expectLater(
            runner.run(_terminationRequest()),
            throwsA(
              isA<LinuxProcessTimeoutException>()
                  .having((error) => error.pid, 'pid', 21)
                  .having(
                    (error) => error.sigtermAttempted,
                    'sigtermAttempted',
                    isTrue,
                  )
                  .having(
                    (error) => error.sigtermDelivered,
                    'sigtermDelivered',
                    isTrue,
                  )
                  .having(
                    (error) => error.sigkillAttempted,
                    'sigkillAttempted',
                    isFalse,
                  )
                  .having(
                    (error) => error.timeout,
                    'timeout',
                    _terminationTimeout,
                  ),
            ),
          );
        } finally {
          fallback.cancel();
          await process.finish(exitCode: 255);
        }

        expect(
          process.signals,
          orderedEquals(<LinuxProcessSignal>[LinuxProcessSignal.sigterm]),
        );
      },
    );

    test('timeout escalates to SIGKILL after the grace period', () async {
      final starter = FakeLinuxProcessStarter();
      final process = ControllableLinuxStartedProcess(pid: 22);
      final runner = DartIoLinuxProcessRunner(processStarter: starter);

      process.killHandler = (signal) {
        if (signal == LinuxProcessSignal.sigkill) {
          unawaited(process.finish(exitCode: 137));
        }
      };
      starter.enqueueProcess(process);

      final fallback = _fallbackFinish(process);
      try {
        await expectLater(
          runner.run(_terminationRequest()),
          throwsA(
            isA<LinuxProcessTimeoutException>()
                .having(
                  (error) => error.sigtermAttempted,
                  'sigtermAttempted',
                  isTrue,
                )
                .having(
                  (error) => error.sigkillAttempted,
                  'sigkillAttempted',
                  isTrue,
                )
                .having(
                  (error) => error.sigkillDelivered,
                  'sigkillDelivered',
                  isTrue,
                )
                .having(
                  (error) => error.terminationGracePeriod,
                  'terminationGracePeriod',
                  _terminationGrace,
                ),
          ),
        );
      } finally {
        fallback.cancel();
        await process.finish(exitCode: 255);
      }

      expect(
        process.signals,
        orderedEquals(<LinuxProcessSignal>[
          LinuxProcessSignal.sigterm,
          LinuxProcessSignal.sigkill,
        ]),
      );
    });

    test(
      'cancellation after spawn uses the same escalation sequence',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 23);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);
        final source = LinuxCancellationSource();

        process.killHandler = (signal) {
          if (signal == LinuxProcessSignal.sigkill) {
            unawaited(process.finish(exitCode: 137));
          }
        };
        starter.enqueueProcess(process);

        final future = runner.run(
          _terminationRequest(),
          cancellationToken: source.token,
        );
        final expectation = expectLater(
          future,
          throwsA(
            isA<LinuxProcessCancellationException>()
                .having((error) => error.pid, 'pid', 23)
                .having(
                  (error) => error.sigtermAttempted,
                  'sigtermAttempted',
                  isTrue,
                )
                .having(
                  (error) => error.sigkillAttempted,
                  'sigkillAttempted',
                  isTrue,
                ),
          ),
        );
        final fallback = _fallbackFinish(process);

        try {
          await Future.wait<void>(<Future<void>>[
            process.stdoutListened,
            process.stderrListened,
          ]);
          expect(source.cancel(), isTrue);
          await expectation;
        } finally {
          fallback.cancel();
          await process.finish(exitCode: 255);
        }

        expect(
          process.signals,
          orderedEquals(<LinuxProcessSignal>[
            LinuxProcessSignal.sigterm,
            LinuxProcessSignal.sigkill,
          ]),
        );
      },
    );

    test(
      'timeout remains the terminal reason when cancellation races later',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 24);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);
        final source = LinuxCancellationSource();

        process.killHandler = (signal) {
          if (signal == LinuxProcessSignal.sigterm) {
            source.cancel();
            unawaited(process.finish(exitCode: 143));
          }
        };
        starter.enqueueProcess(process);

        final fallback = _fallbackFinish(process);
        try {
          await expectLater(
            runner.run(_terminationRequest(), cancellationToken: source.token),
            throwsA(isA<LinuxProcessTimeoutException>()),
          );
        } finally {
          fallback.cancel();
          await process.finish(exitCode: 255);
        }

        expect(source.token.isCancelled, isTrue);
        expect(
          process.signals,
          orderedEquals(<LinuxProcessSignal>[LinuxProcessSignal.sigterm]),
        );
      },
    );

    test(
      'cancellation wins once and a later timeout sends no more signals',
      () async {
        final starter = FakeLinuxProcessStarter();
        final process = ControllableLinuxStartedProcess(pid: 25);
        final runner = DartIoLinuxProcessRunner(processStarter: starter);
        final source = LinuxCancellationSource();

        process.killHandler = (signal) {
          if (signal == LinuxProcessSignal.sigterm) {
            unawaited(process.finish(exitCode: 143));
          }
        };
        starter.enqueueProcess(process);

        final future = runner.run(
          _terminationRequest(),
          cancellationToken: source.token,
        );
        final expectation = expectLater(
          future,
          throwsA(isA<LinuxProcessCancellationException>()),
        );
        final fallback = _fallbackFinish(process);

        try {
          await Future.wait<void>(<Future<void>>[
            process.stdoutListened,
            process.stderrListened,
          ]);
          expect(source.cancel(), isTrue);
          await expectation;
          await Future<void>.delayed(_terminationTimeout + _terminationGrace);
        } finally {
          fallback.cancel();
          await process.finish(exitCode: 255);
        }

        expect(
          process.signals,
          orderedEquals(<LinuxProcessSignal>[LinuxProcessSignal.sigterm]),
        );
      },
    );

    test('repeated cancellation never repeats the signal sequence', () async {
      final starter = FakeLinuxProcessStarter();
      final process = ControllableLinuxStartedProcess(pid: 26);
      final runner = DartIoLinuxProcessRunner(processStarter: starter);
      final source = LinuxCancellationSource();

      process.killHandler = (signal) {
        if (signal == LinuxProcessSignal.sigterm) {
          unawaited(process.finish(exitCode: 143));
        }
      };
      starter.enqueueProcess(process);

      final future = runner.run(
        _terminationRequest(),
        cancellationToken: source.token,
      );
      final expectation = expectLater(
        future,
        throwsA(isA<LinuxProcessCancellationException>()),
      );
      final fallback = _fallbackFinish(process);

      try {
        await Future.wait<void>(<Future<void>>[
          process.stdoutListened,
          process.stderrListened,
        ]);
        expect(source.cancel(), isTrue);
        expect(source.cancel(), isFalse);
        await expectation;
      } finally {
        fallback.cancel();
        await process.finish(exitCode: 255);
      }

      expect(
        process.signals,
        orderedEquals(<LinuxProcessSignal>[LinuxProcessSignal.sigterm]),
      );
    });

    test('forced termination drains and bounds both output streams', () async {
      final starter = FakeLinuxProcessStarter();
      final process = ControllableLinuxStartedProcess(pid: 27);
      final runner = DartIoLinuxProcessRunner(processStarter: starter);
      final source = LinuxCancellationSource();

      process.killHandler = (signal) {
        if (signal == LinuxProcessSignal.sigkill) {
          process.addStdout(utf8.encode('TAIL'));
          process.addStderr(utf8.encode('TAIL'));
          unawaited(process.finish(exitCode: 137));
        }
      };
      starter.enqueueProcess(process);

      final future = runner.run(
        _terminationRequest(),
        cancellationToken: source.token,
      );
      final expectation = expectLater(
        future,
        throwsA(
          isA<LinuxProcessCancellationException>()
              .having(
                (error) => error.stdout?.totalBytes,
                'stdout totalBytes',
                2054,
              )
              .having(
                (error) => error.stdout?.retainedBytes,
                'stdout retainedBytes',
                2048,
              )
              .having(
                (error) => error.stdout?.truncated,
                'stdout truncated',
                isTrue,
              )
              .having(
                (error) => error.stdout?.text.endsWith('TAIL'),
                'stdout suffix',
                isTrue,
              )
              .having(
                (error) => error.stderr?.totalBytes,
                'stderr totalBytes',
                2054,
              )
              .having(
                (error) => error.stderr?.text.endsWith('TAIL'),
                'stderr suffix',
                isTrue,
              ),
        ),
      );
      final fallback = _fallbackFinish(process);

      try {
        await Future.wait<void>(<Future<void>>[
          process.stdoutListened,
          process.stderrListened,
        ]);

        process.addStdout(List<int>.filled(2050, 65, growable: false));
        process.addStderr(List<int>.filled(2050, 66, growable: false));

        expect(source.cancel(), isTrue);
        await expectation;
      } finally {
        fallback.cancel();
        await process.finish(exitCode: 255);
      }

      expect(
        process.signals,
        orderedEquals(<LinuxProcessSignal>[
          LinuxProcessSignal.sigterm,
          LinuxProcessSignal.sigkill,
        ]),
      );
    });
  });
}

LinuxProcessRequest _request({
  int stdoutLimitBytes = 4096,
  int stderrLimitBytes = 4096,
  Duration timeout = const Duration(seconds: 15),
  Duration terminationGracePeriod = const Duration(seconds: 2),
}) {
  return LinuxProcessRequest(
    executable: 'systemctl',
    arguments: const <String>['--user', '--no-pager', 'daemon-reload'],
    environment: const <String, String>{
      'LC_ALL': 'C',
      'TOP_SECRET': 'must-not-leak',
    },
    timeout: timeout,
    terminationGracePeriod: terminationGracePeriod,
    stdoutLimitBytes: stdoutLimitBytes,
    stderrLimitBytes: stderrLimitBytes,
    includeParentEnvironment: false,
  );
}

const Duration _terminationTimeout = Duration(milliseconds: 80);
const Duration _terminationGrace = Duration(milliseconds: 40);
const Duration _fallbackDelay = Duration(milliseconds: 500);

LinuxProcessRequest _terminationRequest() {
  return _request(
    stdoutLimitBytes: 2048,
    stderrLimitBytes: 2048,
    timeout: _terminationTimeout,
    terminationGracePeriod: _terminationGrace,
  );
}

Timer _fallbackFinish(ControllableLinuxStartedProcess process) {
  return Timer(_fallbackDelay, () {
    unawaited(process.finish(exitCode: 255));
  });
}
