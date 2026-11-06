import 'dart:async';
import 'dart:collection';

import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_starter.dart';
import 'package:borj/core/notifications/linux_started_process.dart';

final class FakeLinuxProcessStarter implements LinuxProcessStarter {
  final Queue<_FakeLinuxProcessStartOutcome> _outcomes =
      Queue<_FakeLinuxProcessStartOutcome>();
  final List<LinuxProcessRequest> _requests = <LinuxProcessRequest>[];

  List<LinuxProcessRequest> get requests =>
      List<LinuxProcessRequest>.unmodifiable(_requests);

  int get pendingOutcomeCount => _outcomes.length;

  void enqueueProcess(LinuxStartedProcess process) {
    _outcomes.addLast(_StartedProcessOutcome(process));
  }

  void enqueueFailure(Object error, StackTrace stackTrace) {
    _outcomes.addLast(
      _StartFailureOutcome(error: error, stackTrace: stackTrace),
    );
  }

  @override
  Future<LinuxStartedProcess> start(LinuxProcessRequest request) async {
    _requests.add(request);

    if (_outcomes.isEmpty) {
      throw StateError('No fake Linux process start outcome is queued.');
    }

    return _outcomes.removeFirst().resolve();
  }
}

final class ControllableLinuxStartedProcess implements LinuxStartedProcess {
  ControllableLinuxStartedProcess({
    required this.pid,
    this.sigtermDeliveryResult = true,
    this.sigkillDeliveryResult = true,
  }) {
    _stdoutController = StreamController<List<int>>(
      sync: true,
      onListen: () {
        if (!_stdoutListenedCompleter.isCompleted) {
          _stdoutListenedCompleter.complete();
        }
      },
    );
    _stderrController = StreamController<List<int>>(
      sync: true,
      onListen: () {
        if (!_stderrListenedCompleter.isCompleted) {
          _stderrListenedCompleter.complete();
        }
      },
    );
  }

  @override
  final int pid;

  final bool sigtermDeliveryResult;
  final bool sigkillDeliveryResult;

  void Function(LinuxProcessSignal signal)? killHandler;

  late final StreamController<List<int>> _stdoutController;
  late final StreamController<List<int>> _stderrController;
  final Completer<int> _exitCodeCompleter = Completer<int>.sync();
  final Completer<void> _stdoutListenedCompleter = Completer<void>.sync();
  final Completer<void> _stderrListenedCompleter = Completer<void>.sync();
  final Completer<void> _sigtermObservedCompleter = Completer<void>.sync();
  final Completer<void> _sigkillObservedCompleter = Completer<void>.sync();
  final List<LinuxProcessSignal> _signals = <LinuxProcessSignal>[];

  bool _stdoutClosed = false;
  bool _stderrClosed = false;
  Future<void>? _finishFuture;

  Future<void> get stdoutListened => _stdoutListenedCompleter.future;
  Future<void> get stderrListened => _stderrListenedCompleter.future;
  Future<void> get sigtermObserved => _sigtermObservedCompleter.future;
  Future<void> get sigkillObserved => _sigkillObservedCompleter.future;

  List<LinuxProcessSignal> get signals =>
      List<LinuxProcessSignal>.unmodifiable(_signals);

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  void addStdout(List<int> bytes) {
    _stdoutController.add(List<int>.of(bytes));
  }

  void addStderr(List<int> bytes) {
    _stderrController.add(List<int>.of(bytes));
  }

  void addStdoutError(Object error, StackTrace stackTrace) {
    _stdoutController.addError(error, stackTrace);
  }

  void addStderrError(Object error, StackTrace stackTrace) {
    _stderrController.addError(error, stackTrace);
  }

  Future<void> closeStdout() {
    if (_stdoutClosed) {
      return _stdoutController.done;
    }

    _stdoutClosed = true;
    return _stdoutController.close();
  }

  Future<void> closeStderr() {
    if (_stderrClosed) {
      return _stderrController.done;
    }

    _stderrClosed = true;
    return _stderrController.close();
  }

  bool completeExit(int code) {
    if (_exitCodeCompleter.isCompleted) {
      return false;
    }

    _exitCodeCompleter.complete(code);
    return true;
  }

  Future<void> finish({int exitCode = 0}) {
    return _finishFuture ??= _finish(exitCode);
  }

  Future<void> _finish(int exitCode) async {
    completeExit(exitCode);

    await Future.wait<void>(<Future<void>>[closeStdout(), closeStderr()]);
  }

  @override
  bool kill(LinuxProcessSignal signal) {
    _signals.add(signal);

    switch (signal) {
      case LinuxProcessSignal.sigterm:
        if (!_sigtermObservedCompleter.isCompleted) {
          _sigtermObservedCompleter.complete();
        }
        break;
      case LinuxProcessSignal.sigkill:
        if (!_sigkillObservedCompleter.isCompleted) {
          _sigkillObservedCompleter.complete();
        }
        break;
    }

    killHandler?.call(signal);

    return switch (signal) {
      LinuxProcessSignal.sigterm => sigtermDeliveryResult,
      LinuxProcessSignal.sigkill => sigkillDeliveryResult,
    };
  }
}

sealed class _FakeLinuxProcessStartOutcome {
  const _FakeLinuxProcessStartOutcome();

  Future<LinuxStartedProcess> resolve();
}

final class _StartedProcessOutcome extends _FakeLinuxProcessStartOutcome {
  const _StartedProcessOutcome(this.process);

  final LinuxStartedProcess process;

  @override
  Future<LinuxStartedProcess> resolve() async => process;
}

final class _StartFailureOutcome extends _FakeLinuxProcessStartOutcome {
  const _StartFailureOutcome({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Future<LinuxStartedProcess> resolve() async {
    Error.throwWithStackTrace(error, stackTrace);
  }
}
