import 'linux_systemd_notification_unit.dart';

/// Deterministic contents for one systemd user service and timer pair.
final class LinuxSystemdRenderedUnits {
  const LinuxSystemdRenderedUnits({
    required this.serviceFileName,
    required this.timerFileName,
    required this.serviceContents,
    required this.timerContents,
  });

  final String serviceFileName;
  final String timerFileName;
  final String serviceContents;
  final String timerContents;

  @override
  bool operator ==(Object other) {
    return other is LinuxSystemdRenderedUnits &&
        other.serviceFileName == serviceFileName &&
        other.timerFileName == timerFileName &&
        other.serviceContents == serviceContents &&
        other.timerContents == timerContents;
  }

  @override
  int get hashCode => Object.hash(
    serviceFileName,
    timerFileName,
    serviceContents,
    timerContents,
  );
}

/// Renders one-shot systemd user units without invoking a shell.
///
/// `Persistent=true` lets systemd trigger a missed calendar event when the
/// user's systemd manager becomes available again.
final class LinuxSystemdUnitRenderer {
  const LinuxSystemdUnitRenderer();

  LinuxSystemdRenderedUnits render(LinuxSystemdNotificationUnit unit) {
    final names = LinuxSystemdUnitNames.forScheduleKey(unit.scheduleKey);
    final description = 'Borj scheduled notification ${names.baseName}';

    final command = <String>[
      unit.executablePath,
      ...unit.arguments,
    ].map(_quoteExecWord).join(' ');

    final serviceContents = <String>[
      '[Unit]',
      'Description=$description',
      '',
      '[Service]',
      'Type=oneshot',
      'ExecStart=$command',
    ].join('\n');

    final timerContents = <String>[
      '[Unit]',
      'Description=$description timer',
      '',
      '[Timer]',
      'OnCalendar=${_formatUtcCalendar(unit.scheduledAtUtc)}',
      'AccuracySec=1s',
      'RandomizedDelaySec=0',
      'Persistent=true',
      'Unit=${names.serviceFileName}',
      '',
      '[Install]',
      'WantedBy=timers.target',
    ].join('\n');

    return LinuxSystemdRenderedUnits(
      serviceFileName: names.serviceFileName,
      timerFileName: names.timerFileName,
      serviceContents: '$serviceContents\n',
      timerContents: '$timerContents\n',
    );
  }

  String _formatUtcCalendar(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second UTC';
  }

  String _quoteExecWord(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll(r'$', r'$$')
        .replaceAll('%', '%%');

    return '"$escaped"';
  }
}
