import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test(
    'failed archive open does not change the active game identity',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maia-open-failure-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = SessionRepository(directory);
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      final firstId = (await store.recent()).single.id;
      await store.startNew();
      await store.save({'type': 'game', 'pgn': '1. d4 *'});
      final secondId = (await store.recent()).first.id;
      expect(secondId, isNot(firstId));
      await store.open(firstId);
      final obstruction = Directory('${directory.path}/active.json.pending');
      await obstruction.create();
      await expectLater(
        store.open(secondId),
        throwsA(isA<FileSystemException>()),
      );
      await obstruction.delete();
      expect((await SessionRepository(directory).load())!['pgn'], '1. e4 *');
      // Loading in a different repository must not be needed to repair the live
      // repository's identity after a failed open. Resume the original game.
      await store.save({'type': 'game', 'pgn': '1. e4 e5 *'});
      final recent = await store.recent();
      expect(
        recent.singleWhere((game) => game.id == firstId).data['pgn'],
        '1. e4 e5 *',
      );
      expect(
        recent.singleWhere((game) => game.id == secondId).data['pgn'],
        '1. d4 *',
      );
    },
  );

  test(
    'failed checkpoint write preserves the last save and the queue recovers',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maia-write-failure-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = SessionRepository(directory);
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      final obstruction = Directory('${directory.path}/active.json.pending');
      await obstruction.create();
      await expectLater(
        store.save({'type': 'game', 'pgn': '1. d4 *'}),
        throwsA(isA<FileSystemException>()),
      );
      expect((await SessionRepository(directory).load())!['pgn'], '1. e4 *');
      await obstruction.delete();
      await store.save({'type': 'game', 'pgn': '1. e4 e5 *'});
      expect((await SessionRepository(directory).load())!['pgn'], '1. e4 e5 *');
    },
  );

  test(
    'large archives remain sorted, reopenable, and deletable after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maia-archive-scale-',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory('${directory.path}/games').create();
      for (var i = 0; i < 1000; i++) {
        await File('${directory.path}/games/game-$i.json').writeAsString(
          jsonEncode({
            'version': 1,
            'id': 'game-$i',
            'updatedAt': DateTime.utc(2026)
                .add(Duration(minutes: i))
                .toIso8601String(),
            'data': {
              'type': 'game',
              'pgn': '[Event "Game $i"]\n[Result "*"]\n\n1. e4 *',
            },
          }),
        );
      }
      final store = SessionRepository(directory);
      final watch = Stopwatch()..start();
      final recent = await store.recent();
      watch.stop();
      expect(recent, hasLength(1000));
      expect(recent.first.title, 'Game 999');
      expect(recent.last.title, 'Game 0');
      expect((await store.open('game-450'))!['pgn'], contains('Game 450'));
      await store.deleteMany(['game-999', 'game-450', 'game-0']);
      final restarted = SessionRepository(directory);
      expect(await restarted.load(), isNull);
      final remaining = await restarted.recent();
      expect(remaining, hasLength(997));
      expect(remaining.map((e) => e.id), isNot(contains('game-450')));
      // Host observation, not a phone latency assertion.
      // ignore: avoid_print
      print('ARCHIVE: list 1000 games ${watch.elapsedMilliseconds} ms');
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
