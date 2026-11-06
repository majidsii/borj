import 'package:borj/core/errors/app_failure.dart';

enum TaskStatus {
  planned('planned'),
  inProgress('inProgress'),
  completed('completed'),
  canceled('canceled');

  const TaskStatus(this.storageValue);

  final String storageValue;

  static TaskStatus? tryParseStorage(String value) {
    for (final status in values) {
      if (status.storageValue == value) {
        return status;
      }
    }
    return null;
  }

  static TaskStatus parseStorage(String value) {
    final status = tryParseStorage(value);
    if (status == null) {
      throw const ValidationFailure('وضعیت کار نامعتبر است.');
    }
    return status;
  }
}
