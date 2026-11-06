import 'dart:async';

import 'package:borj/core/notifications/async_fifo_keyed_mutex.dart';
import 'package:borj/core/notifications/async_writer_preferring_rw_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsyncWriterPreferringRwLock', () {
    test(
      'allows concurrent readers when no writer is active or waiting',
      () async {
        final lock = AsyncWriterPreferringRwLock();
        final release = Completer<void>.sync();
        final firstEntered = Completer<void>.sync();
        final secondEntered = Completer<void>.sync();

        final first = lock.runRead(() async {
          firstEntered.complete();
          await release.future;
        });
        final second = lock.runRead(() async {
          secondEntered.complete();
          await release.future;
        });

        await Future.wait<void>(<Future<void>>[
          firstEntered.future.timeout(const Duration(seconds: 1)),
          secondEntered.future.timeout(const Duration(seconds: 1)),
        ]);

        expect(lock.activeReaderCount, 2);
        expect(lock.isWriterActive, isFalse);

        release.complete();
        await Future.wait<void>(<Future<void>>[first, second]);

        expect(lock.activeReaderCount, 0);
      },
    );

    test('writer waits until every active reader releases', () async {
      final lock = AsyncWriterPreferringRwLock();
      final releaseReader = Completer<void>.sync();
      final readerEntered = Completer<void>.sync();
      final writerEntered = Completer<void>.sync();

      final reader = lock.runRead(() async {
        readerEntered.complete();
        await releaseReader.future;
      });

      await readerEntered.future;

      final writer = lock.runWrite(() {
        writerEntered.complete();
      });

      await Future<void>.delayed(Duration.zero);
      expect(writerEntered.isCompleted, isFalse);
      expect(lock.waitingWriterCount, 1);

      releaseReader.complete();
      await writerEntered.future.timeout(const Duration(seconds: 1));
      await Future.wait<void>(<Future<void>>[reader, writer]);
    });

    test('reader arriving after a queued writer cannot bypass it', () async {
      final lock = AsyncWriterPreferringRwLock();
      final releaseFirstReader = Completer<void>.sync();
      final releaseWriter = Completer<void>.sync();
      final firstReaderEntered = Completer<void>.sync();
      final writerEntered = Completer<void>.sync();
      final lateReaderEntered = Completer<void>.sync();
      final events = <String>[];

      final firstReader = lock.runRead(() async {
        events.add('reader-1-enter');
        firstReaderEntered.complete();
        await releaseFirstReader.future;
        events.add('reader-1-exit');
      });

      await firstReaderEntered.future;

      final writer = lock.runWrite(() async {
        events.add('writer-enter');
        writerEntered.complete();
        await releaseWriter.future;
        events.add('writer-exit');
      });

      final lateReader = lock.runRead(() {
        events.add('reader-2-enter');
        lateReaderEntered.complete();
      });

      await Future<void>.delayed(Duration.zero);
      expect(writerEntered.isCompleted, isFalse);
      expect(lateReaderEntered.isCompleted, isFalse);

      releaseFirstReader.complete();
      await writerEntered.future.timeout(const Duration(seconds: 1));

      expect(lateReaderEntered.isCompleted, isFalse);

      releaseWriter.complete();
      await lateReaderEntered.future.timeout(const Duration(seconds: 1));
      await Future.wait<void>(<Future<void>>[firstReader, writer, lateReader]);

      expect(
        events,
        orderedEquals(<String>[
          'reader-1-enter',
          'reader-1-exit',
          'writer-enter',
          'writer-exit',
          'reader-2-enter',
        ]),
      );
    });

    test('queued writers are granted in FIFO order', () async {
      final lock = AsyncWriterPreferringRwLock();
      final releaseReader = Completer<void>.sync();
      final readerEntered = Completer<void>.sync();
      final order = <int>[];

      final reader = lock.runRead(() async {
        readerEntered.complete();
        await releaseReader.future;
      });
      await readerEntered.future;

      final writers = <Future<void>>[
        for (var index = 1; index <= 3; index++)
          lock.runWrite(() {
            order.add(index);
          }),
      ];

      releaseReader.complete();

      await Future.wait<void>(<Future<void>>[reader, ...writers]);

      expect(order, orderedEquals(<int>[1, 2, 3]));
    });

    test(
      'waiting writers drain before queued readers resume together',
      () async {
        final lock = AsyncWriterPreferringRwLock();
        final releaseFirstWriter = Completer<void>.sync();
        final releaseSecondWriter = Completer<void>.sync();
        final firstWriterEntered = Completer<void>.sync();
        final secondWriterEntered = Completer<void>.sync();
        final firstReaderEntered = Completer<void>.sync();
        final secondReaderEntered = Completer<void>.sync();

        final firstWriter = lock.runWrite(() async {
          firstWriterEntered.complete();
          await releaseFirstWriter.future;
        });
        await firstWriterEntered.future;

        final secondWriter = lock.runWrite(() async {
          secondWriterEntered.complete();
          await releaseSecondWriter.future;
        });
        final firstReader = lock.runRead(firstReaderEntered.complete);
        final secondReader = lock.runRead(secondReaderEntered.complete);

        releaseFirstWriter.complete();
        await secondWriterEntered.future.timeout(const Duration(seconds: 1));

        expect(firstReaderEntered.isCompleted, isFalse);
        expect(secondReaderEntered.isCompleted, isFalse);

        releaseSecondWriter.complete();
        await Future.wait<void>(<Future<void>>[
          firstReaderEntered.future.timeout(const Duration(seconds: 1)),
          secondReaderEntered.future.timeout(const Duration(seconds: 1)),
        ]);

        await Future.wait<void>(<Future<void>>[
          firstWriter,
          secondWriter,
          firstReader,
          secondReader,
        ]);
      },
    );

    test('exceptions release the write lock for the next waiter', () async {
      final lock = AsyncWriterPreferringRwLock();
      final secondEntered = Completer<void>.sync();
      final failure = StateError('write failed');

      final first = lock.runWrite<void>(() {
        throw failure;
      });
      final firstExpectation = expectLater(first, throwsA(same(failure)));

      final second = lock.runWrite(secondEntered.complete);

      await firstExpectation;
      await secondEntered.future.timeout(const Duration(seconds: 1));
      await second;

      expect(lock.isWriterActive, isFalse);
      expect(lock.waitingWriterCount, 0);
    });
  });

  group('AsyncFifoKeyedMutex', () {
    test('serializes the same key in strict FIFO order', () async {
      final mutex = AsyncFifoKeyedMutex<String>();
      final releaseFirst = Completer<void>.sync();
      final firstEntered = Completer<void>.sync();
      final events = <String>[];

      final first = mutex.synchronized('timer-a', () async {
        events.add('first-enter');
        firstEntered.complete();
        await releaseFirst.future;
        events.add('first-exit');
      });
      await firstEntered.future;

      final second = mutex.synchronized('timer-a', () {
        events.add('second');
      });
      final third = mutex.synchronized('timer-a', () {
        events.add('third');
      });

      await Future<void>.delayed(Duration.zero);
      expect(events, orderedEquals(<String>['first-enter']));

      releaseFirst.complete();
      await Future.wait<void>(<Future<void>>[first, second, third]);

      expect(
        events,
        orderedEquals(<String>['first-enter', 'first-exit', 'second', 'third']),
      );
    });

    test('allows different keys to execute concurrently', () async {
      final mutex = AsyncFifoKeyedMutex<String>();
      final release = Completer<void>.sync();
      final firstEntered = Completer<void>.sync();
      final secondEntered = Completer<void>.sync();

      final first = mutex.synchronized('timer-a', () async {
        firstEntered.complete();
        await release.future;
      });
      final second = mutex.synchronized('timer-b', () async {
        secondEntered.complete();
        await release.future;
      });

      await Future.wait<void>(<Future<void>>[
        firstEntered.future.timeout(const Duration(seconds: 1)),
        secondEntered.future.timeout(const Duration(seconds: 1)),
      ]);

      expect(mutex.activeKeyCount, 2);

      release.complete();
      await Future.wait<void>(<Future<void>>[first, second]);
    });

    test('an exception releases the key for the next queued action', () async {
      final mutex = AsyncFifoKeyedMutex<String>();
      final nextEntered = Completer<void>.sync();
      final failure = StateError('keyed action failed');

      final failed = mutex.synchronized<void>('timer-a', () {
        throw failure;
      });
      final failedExpectation = expectLater(failed, throwsA(same(failure)));

      final next = mutex.synchronized('timer-a', nextEntered.complete);

      await failedExpectation;
      await nextEntered.future.timeout(const Duration(seconds: 1));
      await next;
    });

    test('evicts idle key state after the final action completes', () async {
      final mutex = AsyncFifoKeyedMutex<String>();

      await mutex.synchronized('timer-a', () {});
      await mutex.synchronized('timer-b', () {});

      expect(mutex.activeKeyCount, 0);
      expect(mutex.containsKey('timer-a'), isFalse);
      expect(mutex.containsKey('timer-b'), isFalse);
    });
  });
}
