// ignore_for_file: prefer_initializing_formals

import 'dart:io';

import 'package:borj/core/notifications/linux_notification_delivery_invocation.dart';
import 'package:borj/core/notifications/linux_notification_delivery_result.dart';
import 'package:borj/core/notifications/linux_notification_delivery_service.dart';

import 'linux_notification_delivery_bootstrap.dart';

typedef LinuxNotificationDeliveryInvocationParser =
    LinuxNotificationDeliveryInvocation Function(List<String> arguments);

abstract interface class NormalApplicationRunner {
  Future<void> run();
}

final class CallbackNormalApplicationRunner implements NormalApplicationRunner {
  const CallbackNormalApplicationRunner(this._callback);

  final Future<void> Function() _callback;

  @override
  Future<void> run() => _callback();
}

abstract interface class ProcessExitCodeSink {
  void setExitCode(int value);
}

final class DartIoProcessExitCodeSink implements ProcessExitCodeSink {
  const DartIoProcessExitCodeSink();

  @override
  void setExitCode(int value) {
    exitCode = value;
  }
}

final class ApplicationEntrypoint {
  const ApplicationEntrypoint({
    required LinuxNotificationDeliveryInvocationParser invocationParser,
    required LinuxNotificationDeliveryService deliveryService,
    required NormalApplicationRunner normalApplicationRunner,
    required ProcessExitCodeSink exitCodeSink,
  }) : _invocationParser = invocationParser,
       _deliveryService = deliveryService,
       _normalApplicationRunner = normalApplicationRunner,
       _exitCodeSink = exitCodeSink;

  final LinuxNotificationDeliveryInvocationParser _invocationParser;
  final LinuxNotificationDeliveryService _deliveryService;
  final NormalApplicationRunner _normalApplicationRunner;
  final ProcessExitCodeSink _exitCodeSink;

  Future<void> run(List<String> arguments) async {
    final LinuxNotificationDeliveryInvocation invocation;
    try {
      invocation = _invocationParser(arguments);
    } catch (error, stackTrace) {
      final result = LinuxNotificationDeliveryResult.invalidArguments(
        error,
        stackTrace,
      );
      _exitCodeSink.setExitCode(result.exitCode);
      return;
    }

    switch (invocation) {
      case LinuxNormalApplicationInvocation():
        await _normalApplicationRunner.run();
      case LinuxHiddenNotificationDeliveryInvocation(:final scheduleId):
        final result = await _deliverWithoutEscaping(scheduleId);
        _exitCodeSink.setExitCode(result.exitCode);
    }
  }

  Future<LinuxNotificationDeliveryResult> _deliverWithoutEscaping(
    String scheduleId,
  ) async {
    try {
      return await _deliveryService.deliver(scheduleId);
    } catch (error, stackTrace) {
      return LinuxNotificationDeliveryResult.initializationFailed(
        error,
        stackTrace,
      );
    }
  }
}

ApplicationEntrypoint buildProductionApplicationEntrypoint({
  required NormalApplicationRunner normalApplicationRunner,
  ProcessExitCodeSink exitCodeSink = const DartIoProcessExitCodeSink(),
  LinuxNotificationDeliveryBootstrap? deliveryBootstrap,
}) {
  final bootstrap =
      deliveryBootstrap ?? ProductionLinuxNotificationDeliveryBootstrap();

  return ApplicationEntrypoint(
    invocationParser: LinuxNotificationDeliveryInvocation.parse,
    deliveryService: LinuxNotificationDeliveryService(
      resourcesFactory: bootstrap,
    ),
    normalApplicationRunner: normalApplicationRunner,
    exitCodeSink: exitCodeSink,
  );
}
