import 'dart:async';
import 'dart:collection';

import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';

final class FakeLinuxProcessRunner implements LinuxProcessRunner {
  final Queue<_FakeLinuxProcessResponse> _responses =
      Queue<_FakeLinuxProcessResponse>();

  int get pendingResponseCount => _responses.length;

  void enqueueResult(LinuxProcessResult result) {
    _responses.addLast(_ResultLinuxProcessResponse(result));
  }

  void enqueueFailure(Object error, StackTrace stackTrace) {
    _responses.addLast(
      _FailureLinuxProcessResponse(error: error, stackTrace: stackTrace),
    );
  }

  ControlledLinuxProcessCall enqueueControlled() {
    final call = ControlledLinuxProcessCall._();
    _responses.addLast(_ControlledLinuxProcessResponse(call));
    return call;
  }

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    if (_responses.isEmpty) {
      throw StateError(
        'No fake Linux process response is queued for '
        '${request.executable} ${request.arguments}.',
      );
    }

    final response = _responses.removeFirst();

    return response.resolve(request, cancellationToken: cancellationToken);
  }
}

final class ControlledLinuxProcessInvocation {
  const ControlledLinuxProcessInvocation({
    required this.request,
    required this.cancellationToken,
  });

  final LinuxProcessRequest request;
  final LinuxCancellationToken? cancellationToken;
}

final class ControlledLinuxProcessCall {
  ControlledLinuxProcessCall._();

  final Completer<ControlledLinuxProcessInvocation> _invocationCompleter =
      Completer<ControlledLinuxProcessInvocation>.sync();
  final Completer<LinuxProcessResult> _resultCompleter =
      Completer<LinuxProcessResult>.sync();
  final Completer<void> _cancellationObservedCompleter = Completer<void>.sync();

  Future<ControlledLinuxProcessInvocation> get invocation =>
      _invocationCompleter.future;

  Future<void> get whenCancellationObserved =>
      _cancellationObservedCompleter.future;

  bool complete(LinuxProcessResult result) {
    if (_resultCompleter.isCompleted) {
      return false;
    }

    _resultCompleter.complete(result);
    return true;
  }

  bool fail(Object error, StackTrace stackTrace) {
    if (_resultCompleter.isCompleted) {
      return false;
    }

    _resultCompleter.completeError(error, stackTrace);
    return true;
  }

  Future<LinuxProcessResult> _bind(
    LinuxProcessRequest request, {
    required LinuxCancellationToken? cancellationToken,
  }) {
    if (_invocationCompleter.isCompleted) {
      throw StateError(
        'A controlled Linux process call can only be invoked once.',
      );
    }

    _invocationCompleter.complete(
      ControlledLinuxProcessInvocation(
        request: request,
        cancellationToken: cancellationToken,
      ),
    );

    if (cancellationToken != null) {
      unawaited(
        cancellationToken.whenCancelled.then((_) {
          if (!_cancellationObservedCompleter.isCompleted) {
            _cancellationObservedCompleter.complete();
          }
        }),
      );
    }

    return _resultCompleter.future;
  }
}

sealed class _FakeLinuxProcessResponse {
  const _FakeLinuxProcessResponse();

  Future<LinuxProcessResult> resolve(
    LinuxProcessRequest request, {
    required LinuxCancellationToken? cancellationToken,
  });
}

final class _ResultLinuxProcessResponse extends _FakeLinuxProcessResponse {
  const _ResultLinuxProcessResponse(this.result);

  final LinuxProcessResult result;

  @override
  Future<LinuxProcessResult> resolve(
    LinuxProcessRequest request, {
    required LinuxCancellationToken? cancellationToken,
  }) async {
    return result;
  }
}

final class _FailureLinuxProcessResponse extends _FakeLinuxProcessResponse {
  const _FailureLinuxProcessResponse({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Future<LinuxProcessResult> resolve(
    LinuxProcessRequest request, {
    required LinuxCancellationToken? cancellationToken,
  }) async {
    Error.throwWithStackTrace(error, stackTrace);
  }
}

final class _ControlledLinuxProcessResponse extends _FakeLinuxProcessResponse {
  const _ControlledLinuxProcessResponse(this.call);

  final ControlledLinuxProcessCall call;

  @override
  Future<LinuxProcessResult> resolve(
    LinuxProcessRequest request, {
    required LinuxCancellationToken? cancellationToken,
  }) {
    return call._bind(request, cancellationToken: cancellationToken);
  }
}
