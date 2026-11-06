import 'dart:convert';

import 'linux_systemd_schedule_registry_exception.dart';

/// Immutable input for one Linux systemd user-timer notification delivery.
///
/// The executable is invoked directly by systemd without a shell.
final class LinuxSystemdNotificationUnit {
  factory LinuxSystemdNotificationUnit({
    required String scheduleKey,
    required DateTime scheduledAtUtc,
    required String executablePath,
    List<String> arguments = const <String>[],
  }) {
    _validateSafeText(scheduleKey, fieldName: 'scheduleKey', allowEmpty: false);

    if (utf8.encode(scheduleKey).length > 512) {
      throw ArgumentError.value(
        scheduleKey,
        'scheduleKey',
        'must be at most 512 UTF-8 bytes',
      );
    }

    if (!scheduledAtUtc.isUtc) {
      throw ArgumentError.value(
        scheduledAtUtc,
        'scheduledAtUtc',
        'must be a UTC DateTime',
      );
    }

    _validateSafeText(
      executablePath,
      fieldName: 'executablePath',
      allowEmpty: false,
    );
    if (!executablePath.startsWith('/')) {
      throw ArgumentError.value(
        executablePath,
        'executablePath',
        'must be an absolute path',
      );
    }

    for (var index = 0; index < arguments.length; index += 1) {
      _validateSafeText(
        arguments[index],
        fieldName: 'arguments[$index]',
        allowEmpty: true,
      );
    }

    return LinuxSystemdNotificationUnit._(
      scheduleKey,
      scheduledAtUtc,
      executablePath,
      List<String>.unmodifiable(arguments),
    );
  }

  const LinuxSystemdNotificationUnit._(
    this.scheduleKey,
    this.scheduledAtUtc,
    this.executablePath,
    this.arguments,
  );

  final String scheduleKey;
  final DateTime scheduledAtUtc;
  final String executablePath;
  final List<String> arguments;

  static void _validateSafeText(
    String value, {
    required String fieldName,
    required bool allowEmpty,
  }) {
    if (!allowEmpty && value.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }

    if (value.contains('\u0000') ||
        value.contains('\n') ||
        value.contains('\r')) {
      throw ArgumentError.value(
        value,
        fieldName,
        'must not contain NUL or line breaks',
      );
    }
  }
}

/// Stable systemd user-unit file names derived from a schedule key.
///
/// The original key is never included in the file name.
final class LinuxSystemdUnitNames {
  const LinuxSystemdUnitNames._(this.baseName);

  factory LinuxSystemdUnitNames.forScheduleKey(String scheduleKey) {
    if (scheduleKey.isEmpty) {
      throw ArgumentError.value(
        scheduleKey,
        'scheduleKey',
        'must not be empty',
      );
    }

    final hash = _fnv1a64(utf8.encode(scheduleKey));
    final hex = hash.toRadixString(16).padLeft(16, '0');

    return LinuxSystemdUnitNames._('borj-notification-$hex');
  }

  factory LinuxSystemdUnitNames.parseBaseName(String baseName) {
    final match = _baseNamePattern.firstMatch(baseName);

    if (match == null || match.start != 0 || match.end != baseName.length) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'baseName',
      );
    }

    return LinuxSystemdUnitNames._(baseName);
  }

  static final RegExp _baseNamePattern = RegExp(
    r'^borj-notification-[0-9a-f]{16}$',
  );

  final String baseName;

  String get serviceFileName => '$baseName.service';

  String get timerFileName => '$baseName.timer';

  /// Computes FNV-1a in an explicitly unsigned 64-bit BigInt domain.
  ///
  /// Using BigInt avoids the platform-dependent signed representation of a
  /// 64-bit Dart [int] when the hash's high bit is set.
  static BigInt _fnv1a64(List<int> bytes) {
    final offsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask64 = BigInt.parse('ffffffffffffffff', radix: 16);

    var hash = offsetBasis;
    for (final byte in bytes) {
      hash ^= BigInt.from(byte);
      hash = (hash * prime) & mask64;
    }

    return hash;
  }

  @override
  bool operator ==(Object other) {
    return other is LinuxSystemdUnitNames && other.baseName == baseName;
  }

  @override
  int get hashCode => baseName.hashCode;
}
