final class LinuxSystemdTimerName {
  LinuxSystemdTimerName._({required this.value, required this.identityHex});

  static final RegExp _pattern = RegExp(
    r'^borj-notification-([0-9a-f]{16})\.timer$',
  );

  final String value;
  final String identityHex;

  String get serviceName =>
      '${value.substring(0, value.length - '.timer'.length)}.service';

  static LinuxSystemdTimerName parse(String value) {
    final match = _pattern.firstMatch(value);

    if (match == null || match.start != 0 || match.end != value.length) {
      throw FormatException('Invalid borj systemd timer name.', value);
    }

    return LinuxSystemdTimerName._(value: value, identityHex: match.group(1)!);
  }

  static bool isValid(String value) {
    final match = _pattern.firstMatch(value);

    return match != null && match.start == 0 && match.end == value.length;
  }

  @override
  bool operator ==(Object other) {
    return other is LinuxSystemdTimerName && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
