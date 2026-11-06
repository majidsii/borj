import 'dart:convert';

import 'package:borj/core/notifications/notification_route_intent.dart';
import 'package:borj/core/notifications/notification_route_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const Object _absent = Object();

void main() {
  const parser = NotificationRouteParser();

  group('NotificationRouteParser explicit routes', () {
    test('parses a task route into a typed task intent', () {
      final intent = parser.parse(_payload(route: '/tasks/task_1-A'));

      expect(intent, isA<NotificationTaskRouteIntent>());
      expect((intent! as NotificationTaskRouteIntent).taskId, 'task_1-A');
    });

    test('parses a habit route into a typed habit intent', () {
      final intent = parser.parse(_payload(route: '/habits/habit-2'));

      expect(intent, isA<NotificationHabitRouteIntent>());
      expect((intent! as NotificationHabitRouteIntent).habitId, 'habit-2');
    });

    test('parses a challenge route into a typed challenge intent', () {
      final intent = parser.parse(_payload(route: '/challenges/challenge_3'));

      expect(intent, isA<NotificationChallengeRouteIntent>());
      expect(
        (intent! as NotificationChallengeRouteIntent).challengeId,
        'challenge_3',
      );
    });

    test('parses a goal route into a typed goal intent', () {
      final intent = parser.parse(_payload(route: '/goals/goal-4'));

      expect(intent, isA<NotificationGoalRouteIntent>());
      expect((intent! as NotificationGoalRouteIntent).goalId, 'goal-4');
    });

    test('parses a debt route into a typed debt intent', () {
      final intent = parser.parse(_payload(route: '/finance/debts/debt_5'));

      expect(intent, isA<NotificationDebtRouteIntent>());
      expect((intent! as NotificationDebtRouteIntent).debtId, 'debt_5');
    });

    test('parses an installment route into a typed installment intent', () {
      final intent = parser.parse(
        _payload(route: '/finance/installments/installment-6'),
      );

      expect(intent, isA<NotificationInstallmentRouteIntent>());
      expect(
        (intent! as NotificationInstallmentRouteIntent).installmentId,
        'installment-6',
      );
    });

    test('parses a transaction route into a typed transaction intent', () {
      final intent = parser.parse(
        _payload(route: '/finance/transactions/transaction_7'),
      );

      expect(intent, isA<NotificationTransactionRouteIntent>());
      expect(
        (intent! as NotificationTransactionRouteIntent).transactionId,
        'transaction_7',
      );
    });

    test('parses the tasks section route', () {
      expect(
        parser.parse(_payload(route: '/tasks')),
        const NotificationSectionRouteIntent(NotificationSection.tasks),
      );
    });

    test('parses the finance section route', () {
      expect(
        parser.parse(_payload(route: '/finance')),
        const NotificationSectionRouteIntent(NotificationSection.finance),
      );
    });

    test('parses the settings section route', () {
      expect(
        parser.parse(_payload(route: '/settings')),
        const NotificationSectionRouteIntent(NotificationSection.settings),
      );
    });
  });

  group('NotificationRouteParser owner fallback', () {
    final cases =
        <
          ({
            String ownerType,
            String ownerId,
            Type expectedType,
            String Function(NotificationRouteIntent intent) readId,
          })
        >[
          (
            ownerType: 'task',
            ownerId: 'task-1',
            expectedType: NotificationTaskRouteIntent,
            readId: (intent) => (intent as NotificationTaskRouteIntent).taskId,
          ),
          (
            ownerType: 'habit',
            ownerId: 'habit-1',
            expectedType: NotificationHabitRouteIntent,
            readId: (intent) =>
                (intent as NotificationHabitRouteIntent).habitId,
          ),
          (
            ownerType: 'challenge',
            ownerId: 'challenge-1',
            expectedType: NotificationChallengeRouteIntent,
            readId: (intent) =>
                (intent as NotificationChallengeRouteIntent).challengeId,
          ),
          (
            ownerType: 'goal',
            ownerId: 'goal-1',
            expectedType: NotificationGoalRouteIntent,
            readId: (intent) => (intent as NotificationGoalRouteIntent).goalId,
          ),
          (
            ownerType: 'debt',
            ownerId: 'debt-1',
            expectedType: NotificationDebtRouteIntent,
            readId: (intent) => (intent as NotificationDebtRouteIntent).debtId,
          ),
          (
            ownerType: 'installment',
            ownerId: 'installment-1',
            expectedType: NotificationInstallmentRouteIntent,
            readId: (intent) =>
                (intent as NotificationInstallmentRouteIntent).installmentId,
          ),
          (
            ownerType: 'transaction',
            ownerId: 'transaction-1',
            expectedType: NotificationTransactionRouteIntent,
            readId: (intent) =>
                (intent as NotificationTransactionRouteIntent).transactionId,
          ),
        ];

    for (final testCase in cases) {
      test(
        'falls back from ${testCase.ownerType} owner when route is absent',
        () {
          final intent = parser.parse(
            _payload(ownerType: testCase.ownerType, ownerId: testCase.ownerId),
          );

          expect(intent.runtimeType, testCase.expectedType);
          expect(testCase.readId(intent!), testCase.ownerId);
        },
      );
    }

    test('supports the nested owner representation', () {
      final intent = parser.parse(
        _payload(owner: const {'type': 'task', 'id': 'nested-task'}),
      );

      expect(intent, const NotificationTaskRouteIntent('nested-task'));
    });

    test('does not fall back when an explicit route is invalid', () {
      final intent = parser.parse(
        _payload(route: '/admin', ownerType: 'task', ownerId: 'safe-task'),
      );

      expect(intent, isNull);
    });
  });

  group('NotificationRouteParser rejects unsafe payloads', () {
    test('ignores malformed JSON', () {
      expect(parser.parse('{not-json'), isNull);
    });

    test('ignores a non-object JSON payload', () {
      expect(parser.parse(jsonEncode(<String>['/tasks/task-1'])), isNull);
    });

    test('ignores an unknown route', () {
      expect(parser.parse(_payload(route: '/admin')), isNull);
    });

    test('ignores an empty entity id', () {
      expect(parser.parse(_payload(route: '/tasks/')), isNull);
    });

    test('ignores a route with a query string', () {
      expect(parser.parse(_payload(route: '/tasks/task-1?tab=notes')), isNull);
    });

    test('ignores a route with a fragment', () {
      expect(parser.parse(_payload(route: '/tasks/task-1#notes')), isNull);
    });

    test('ignores a traversal route', () {
      expect(parser.parse(_payload(route: '/tasks/../settings')), isNull);
    });

    test('ignores an encoded traversal id', () {
      expect(parser.parse(_payload(route: '/tasks/%2e%2e')), isNull);
    });

    test('ignores a route with an extra path segment', () {
      expect(parser.parse(_payload(route: '/tasks/task-1/edit')), isNull);
    });

    test('ignores an unsupported payload version', () {
      expect(
        parser.parse(_payload(version: 2, route: '/tasks/task-1')),
        isNull,
      );
    });

    test('ignores conflicting version aliases', () {
      final payload = jsonEncode(<String, Object?>{
        'version': 1,
        'v': 2,
        'route': '/tasks/task-1',
      });

      expect(parser.parse(payload), isNull);
    });

    test('ignores an unsupported owner type', () {
      expect(
        parser.parse(_payload(ownerType: 'admin', ownerId: 'admin-1')),
        isNull,
      );
    });

    test('ignores an owner with an invalid id', () {
      expect(
        parser.parse(_payload(ownerType: 'task', ownerId: '../settings')),
        isNull,
      );
    });

    test('accepts an entity id at the 128 character limit', () {
      final id = List<String>.filled(128, 'a').join();

      expect(
        parser.parse(_payload(route: '/tasks/$id')),
        NotificationTaskRouteIntent(id),
      );
    });

    test('ignores an entity id above the 128 character limit', () {
      final id = List<String>.filled(129, 'a').join();

      expect(parser.parse(_payload(route: '/tasks/$id')), isNull);
    });
  });
}

String _payload({
  Object? version = 1,
  Object? route = _absent,
  Object? ownerType,
  Object? ownerId,
  Map<String, Object?>? owner,
}) {
  final payload = <String, Object?>{'version': version};

  if (!identical(route, _absent)) {
    payload['route'] = route;
  }
  if (ownerType != null) {
    payload['ownerType'] = ownerType;
  }
  if (ownerId != null) {
    payload['ownerId'] = ownerId;
  }
  if (owner != null) {
    payload['owner'] = owner;
  }

  return jsonEncode(payload);
}
