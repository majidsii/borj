import 'package:borj/core/errors/app_failure.dart';
import 'package:borj/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskStatus storage contract', () {
    test('uses explicit stable storage values in workflow order', () {
      expect(
        TaskStatus.values.map((status) => status.storageValue).toList(),
        <String>['planned', 'inProgress', 'completed', 'canceled'],
      );
    });

    test('round trips every canonical storage value', () {
      for (final status in TaskStatus.values) {
        expect(TaskStatus.tryParseStorage(status.storageValue), same(status));
        expect(TaskStatus.parseStorage(status.storageValue), same(status));
      }
    });

    test('rejects unknown and non-canonical storage values', () {
      for (final value in <String>[
        '',
        ' planned',
        'planned ',
        'PLANNED',
        'in_progress',
        'done',
        'cancelled',
      ]) {
        expect(
          TaskStatus.tryParseStorage(value),
          isNull,
          reason: 'Unexpectedly accepted "$value".',
        );
        expect(
          () => TaskStatus.parseStorage(value),
          throwsA(isA<ValidationFailure>()),
          reason: 'Unexpectedly parsed "$value".',
        );
      }
    });

    test('keeps all canonical storage values unique', () {
      final values = TaskStatus.values
          .map((status) => status.storageValue)
          .toList(growable: false);

      expect(values.toSet(), hasLength(values.length));
    });
  });
}
