import 'dart:collection';
import 'dart:convert';

import 'package:borj/core/notifications/linux_bounded_output.dart';
import 'package:borj/core/notifications/linux_cancellation_token.dart';
import 'package:borj/core/notifications/linux_process_request.dart';
import 'package:borj/core/notifications/linux_process_result.dart';
import 'package:borj/core/notifications/linux_process_runner.dart';
import 'package:borj/core/notifications/linux_systemd_notification_unit.dart';

final class ControlledLinuxProcessRunner implements LinuxProcessRunner {
  ControlledLinuxProcessRunner({List<String>? operations})
    : operations = operations ?? <String>[];

  final List<String> operations;
  final Queue<_ControlledResponse> _responses = Queue<_ControlledResponse>();

  int get pendingResponseCount => _responses.length;

  void enqueueSuccess({
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
  }) {
    _responses.addLast(
      _ControlledResponse(exitCode: exitCode, stdout: stdout, stderr: stderr),
    );
  }

  void enqueueStatus(
    LinuxSystemdUnitNames names, {
    String loadState = 'loaded',
    String activeState = 'active',
    String subState = 'waiting',
    String unitFileState = 'enabled',
    String result = 'success',
  }) {
    enqueueSuccess(
      stdout: <String>[
        'Id=${names.timerFileName}',
        'LoadState=$loadState',
        'ActiveState=$activeState',
        'SubState=$subState',
        'UnitFileState=$unitFileState',
        'Result=$result',
        '',
      ].join('\n'),
    );
  }

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    operations.add(_operationFor(request));

    if (_responses.isEmpty) {
      throw StateError(
        'No controlled process response is queued for '
        '${request.executable} ${request.arguments}.',
      );
    }

    final response = _responses.removeFirst();

    return LinuxProcessResult(
      executable: request.executable,
      arguments: request.arguments,
      pid: 1055,
      exitCode: response.exitCode,
      duration: const Duration(milliseconds: 4),
      stdout: _output(response.stdout),
      stderr: _output(response.stderr),
    );
  }

  String _operationFor(LinuxProcessRequest request) {
    final arguments = request.arguments;

    if (arguments.contains('daemon-reload')) {
      return 'driver.reload';
    }
    if (arguments.contains('show')) {
      return 'driver.status';
    }
    if (arguments.contains('enable')) {
      return 'driver.enable';
    }
    if (arguments.contains('disable')) {
      return 'driver.disable';
    }

    return 'driver.process';
  }

  LinuxBoundedOutput _output(String text) {
    final bytes = utf8.encode(text);

    return LinuxBoundedOutput(
      text: text,
      totalBytes: bytes.length,
      retainedBytes: bytes.length,
      droppedBytes: 0,
      truncated: false,
      malformedUtf8: false,
    );
  }
}

final class _ControlledResponse {
  const _ControlledResponse({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}
