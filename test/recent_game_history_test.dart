import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> game(String? date, {String note = ''}) => {
  'schema': 1,
  'type': 'game',
  'recentState': 'completed',
  'pgn':
      '${date == null ? '' : '[Date "$date"]\n'}[Result "1-0"]\n\n1. e4 {$note} 1-0',
};

void main() {
  late Directory directory;
  late SessionRepository store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('maia-history-');
    store = SessionRepository(directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  Future<File> fixture(
    String id,
    String? date, {
    String updated = '2030-01-01T00:00:00Z',
    Object? history,
    bool active = false,
    int version = 1,
    Map<String, Object?>? data,
  }) async {
    final file = File(
      active
          ? '${directory.path}/active.json'
          : '${directory.path}/games/$id.json',
    );
    await file.parent.create(recursive: true);
    final payload = <String, Object?>{
      'version': version,
      'id': id,
      'updatedAt': updated,
      'data': data ?? game(date),
    };
    if (history != null) payload['gameHistory'] = history;
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  test(
    'legacy listing is read-only and sorts original dates, not edits',
    () async {
      final older = await fixture(
        'old-game',
        '2020.02.29',
        updated: '2035-01-01T00:00:00Z',
      );
      final newer = await fixture(
        'new-game',
        '2021.01.03',
        updated: '2021-01-03T00:00:00Z',
      );
      final bytes = [await older.readAsBytes(), await newer.readAsBytes()];
      final recent = await store.recent();
      expect(recent.map((e) => e.id), ['new-game', 'old-game']);
      expect(recent.last.history.playedOn, '2020-02-29');
      expect(recent.last.history.playedDate, DateTime.utc(2020, 2, 29));
      expect(recent.last.history.startedAt, isNull);
      expect(await older.readAsBytes(), bytes[0]);
      expect(await newer.readAsBytes(), bytes[1]);
    },
  );

  test('open, review notes, restart and archive preserve inferred history and order', () async {
    await fixture('older', '2020.02.29');
    await fixture('newer', '2021.01.03');
    final initial = (await store.recent()).last;
    await store.open('older');
    await store.save({
      'type': 'review',
      'activeGame': game('2040.12.31'),
      'session': {'pgn': '[Date "2050.01.01"]\n\n1. e4 {new review note} *'},
    });
    final edited = (await store.recent()).last;
    expect(edited.id, 'older');
    expect(edited.history.playedOn, initial.history.playedOn);
    expect(edited.updatedAt, isNot(initial.updatedAt));
    store = SessionRepository(directory);
    await store.load();
    await store.startNew();
    expect((await store.recent()).map((e) => e.id), ['newer', 'older']);
    expect((await store.recent()).last.history.playedOn, '2020-02-29');
    final envelope = jsonDecode(
      await File('${directory.path}/games/older.json').readAsString(),
    ) as Map;
    expect(envelope['version'], 1);
    expect((envelope['gameHistory'] as Map)['playedOn'], '2020-02-29');
  });

  test(
    'explicit new games retain local calendar day and UTC start instant',
    () async {
      final start = DateTime(2024, 2, 29, 0, 15);
      await store.startNew(gameStartedAt: start);
      await store.save(game('1999.01.01'));
      final first = (await store.recent()).single;
      expect(first.history.playedOn, '2024-02-29');
      expect(first.history.startedAt, start.toUtc());
      expect(first.history.playedDate!.isUtc, isTrue);
      await store.startNew(gameStartedAt: DateTime(2024, 3, 1, 0, 5));
      await store.save(game('1999.01.01'));
      final recent = await store.recent();
      expect(recent.first.history.playedOn, '2024-03-01');
      expect(recent.last.history.playedOn, '2024-02-29');
      await store.discardActive();
      expect((await store.recent()).single.id, first.id);
      await store.delete(first.id);
      expect(await SessionRepository(directory).recent(), isEmpty);
    },
  );

  for (final date in [
    null,
    '????.??.??',
    '2024.02.??',
    '2023.02.29',
    '2024.13.01',
    '2024.04.31',
    '2024.00.10',
  ]) {
    test(
      'legacy invalid or missing date $date remains explicitly unknown after edits',
      () async {
        await fixture('unknown', date);
        expect((await store.recent()).single.history.playedOn, isNull);
        await store.open('unknown');
        await store.save(game('2024.02.29'));
        store = SessionRepository(directory);
        await store.load();
        expect((await store.recent()).single.history.playedOn, isNull);
        expect((await store.recent()).single.history.startedAt, isNull);
      },
    );
  }

  test(
    'duplicate Date headers are ambiguous, even with one valid date',
    () async {
      await fixture(
        'duplicate',
        null,
        data: {
          ...game(null),
          'pgn': '[Date "2024.02.29"]\n[Date "2024.03.01"]\n\n*',
        },
      );
      expect((await store.recent()).single.history.playedOn, isNull);
    },
  );

  test('legacy review derives date from active game, not review PGN', () async {
    await fixture(
      'review',
      null,
      data: {
        'type': 'review',
        'activeGame': game('2020.02.29'),
        'session': {'pgn': '[Date "2040.01.01"]\n\n*'},
      },
    );
    expect((await store.recent()).single.history.playedOn, '2020-02-29');
    await store.open('review');
    expect((await store.recent()).single.history.playedOn, '2020-02-29');
  });

  test('same-day starts sort by instant and unknown dates stay last deterministically', () async {
    for (final id in ['unknown-b', 'unknown-a']) {
      await fixture(id, null, updated: '2099-01-01T00:00:00Z');
    }
    for (final hour in [1, 3, 2]) {
      await fixture(
        'known-$hour',
        null,
        history: {
          'version': 1,
          'playedOn': '2024-02-29',
          'startedAt': DateTime.utc(2024, 2, 29, hour).toIso8601String(),
        },
      );
    }
    final first = (await store.recent()).map((e) => e.id).toList();
    expect(first.take(3), ['known-3', 'known-2', 'known-1']);
    expect(first.skip(3).toSet(), {'unknown-a', 'unknown-b'});
    expect(
      (await SessionRepository(directory).recent()).map((e) => e.id),
      first,
    );
  });

  test('legacy preference migration infers PGN date without inventing start instant', () async {
    SharedPreferences.setMockInitialValues({
      'activeSessionV1': jsonEncode(game('2020.02.29')),
    });
    final prefs = await SharedPreferences.getInstance();
    await ActiveSessionStore.restoreOrMigrate(store, prefs);
    expect(prefs.getString('activeSessionV1'), isNull);
    final history = (await store.recent()).single.history;
    expect(history.playedOn, '2020-02-29');
    expect(history.startedAt, isNull);
  });

  test(
    'Date-shaped tags inside movetext cannot invent a historical date',
    () async {
      await fixture(
        'comment-date',
        null,
        data: {
          ...game(null),
          'pgn': '[Result "1-0"]\n\n1. e4 {[Date "2024.02.29"]} 1-0',
        },
      );
      expect((await store.recent()).single.history.playedOn, isNull);
    },
  );

  test('explicit malformed date metadata remains unknown rather than trusting edited PGN', () async {
    await fixture(
      'malformed-date',
      '2024.02.29',
      history: {
        'version': 1,
        'playedOn': '2023-02-29',
        'startedAt': '2023-03-01T00:00:00.000Z',
      },
    );
    expect((await store.recent()).single.history.playedOn, isNull);
    await store.open('malformed-date');
    await store.save(game('2025.01.01'));
    final result = (await SessionRepository(directory).recent()).single;
    expect(result.history.playedOn, isNull);
    expect(result.history.startedAt, isNull);
  });

  test(
    'invalid start timestamp does not normalize into a plausible game instant',
    () {
      for (final timestamp in [
        '2024-02-30T00:00:00.000Z',
        '2024-02-29T00:00:00',
        'not-a-date',
      ]) {
        final history = GameHistory.fromJson({
          'version': 1,
          'playedOn': '2024-02-29',
          'startedAt': timestamp,
        });
        expect(history.playedOn, '2024-02-29');
        expect(history.startedAt, isNull);
      }
    },
  );

  test(
    'migration of undated preference remains unknown after a later PGN edit',
    () async {
      SharedPreferences.setMockInitialValues({
        'activeSessionV1': jsonEncode(game(null)),
      });
      final prefs = await SharedPreferences.getInstance();
      await ActiveSessionStore.restoreOrMigrate(store, prefs);
      await store.save(game('2024.02.29'));
      expect(
        (await SessionRepository(directory).recent()).single.history.playedOn,
        isNull,
      );
    },
  );

  test(
    'opening a future archive cannot checkpoint or rewrite the current game',
    () async {
      await store.startNew(gameStartedAt: DateTime(2024, 2, 29));
      await store.save(game('2024.02.29'));
      final active = File('${directory.path}/active.json');
      final currentBytes = await active.readAsBytes();
      final future = await fixture('future-game', '2020.01.01', version: 99);
      final futureBytes = await future.readAsBytes();
      await expectLater(
        store.open('future-game'),
        throwsA(isA<UnsupportedSessionFormatException>()),
      );
      expect(await active.readAsBytes(), currentBytes);
      expect(await future.readAsBytes(), futureBytes);
    },
  );

  test(
    'future backup with valid primary cannot be overwritten by a checkpoint',
    () async {
      final primary = await fixture('protected', '2020.02.29', active: true);
      final backup = File('${primary.path}.previous');
      await backup.writeAsString(
        jsonEncode({
          'version': 99,
          'id': 'protected',
          'data': game('2019.01.01'),
        }),
      );
      final before = [await primary.readAsBytes(), await backup.readAsBytes()];
      await expectLater(
        store.save(game('2024.02.29')),
        throwsA(isA<UnsupportedSessionFormatException>()),
      );
      expect(await primary.readAsBytes(), before[0]);
      expect(await backup.readAsBytes(), before[1]);
    },
  );

  for (final updatedDate in ['2040.12.31', null]) {
    test(
      'first save of legacy active keeps original date before payload replacement $updatedDate',
      () async {
        await fixture(
          'legacy-active',
          '2020.02.29',
          active: true,
          data: {
            'type': 'review',
            'activeGame': game('2020.02.29'),
            'session': {'pgn': '[Date "2050.01.01"]\n\n*'},
          },
        );
        await store.save({
          'type': 'review',
          'activeGame': game(updatedDate),
          'session': {'pgn': '[Date "2060.01.01"]\n\n*'},
        });
        final recent = (await SessionRepository(directory).recent()).single;
        expect(recent.history.playedOn, '2020-02-29');
        expect(recent.history.startedAt, isNull);
        expect(recent.id, 'legacy-active');
      },
    );
  }

  test('mutating returned nested load and open data cannot change cached checkpoint or history', () async {
    await fixture(
      'detached',
      '2020.02.29',
      active: true,
      data: {
        'type': 'review',
        'activeGame': {
          ...game('2020.02.29'),
          'notes': <String>['original'],
        },
        'session': {'pgn': '[Date "2050.01.01"]\n\n*'},
      },
    );
    final loaded = (await store.load())!;
    (loaded['activeGame'] as Map)['pgn'] = '[Date "2090.01.01"]\n\n*';
    ((loaded['activeGame'] as Map)['notes'] as List).add('mutated');
    await store.startNew();
    final archived = (await store.recent()).single;
    expect(archived.data['pgn'], contains('2020.02.29'));
    expect(archived.data['notes'], ['original']);
    expect(archived.history.playedOn, '2020-02-29');
    final opened = (await store.open('detached'))!;
    (opened['notes'] as List).add('open mutation');
    opened['pgn'] = '[Date "2091.01.01"]\n\n*';
    await store.startNew();
    final reopened = (await store.open('detached'))!;
    expect(reopened['pgn'], contains('2020.02.29'));
    expect(reopened['notes'], ['original']);
    expect((await store.recent()).single.history.playedOn, '2020-02-29');
  });

  test('future pending generation blocks mutations and preference migration without file changes', () async {
    final primary = await fixture(
      'pending-protected',
      '2020.02.29',
      active: true,
    );
    final pending = File('${primary.path}.pending');
    await pending.writeAsString(
      jsonEncode({
        'version': 99,
        'id': 'pending-protected',
        'data': game('2040.01.01'),
      }),
    );
    final before = [await primary.readAsBytes(), await pending.readAsBytes()];
    for (final action in [
      () => store.save(game(null)),
      () => store.startNew(),
      () => store.discardActive(),
      () => store.delete('pending-protected'),
    ]) {
      await expectLater(
        action(),
        throwsA(isA<UnsupportedSessionFormatException>()),
      );
      expect(await primary.readAsBytes(), before[0]);
      expect(await pending.readAsBytes(), before[1]);
    }
    SharedPreferences.setMockInitialValues({
      'activeSessionV1': jsonEncode(game('2024.01.01')),
    });
    final prefs = await SharedPreferences.getInstance();
    await expectLater(
      ActiveSessionStore.restoreOrMigrate(store, prefs),
      throwsA(isA<UnsupportedSessionFormatException>()),
    );
    expect(prefs.getString('activeSessionV1'), isNotNull);
    expect(await primary.readAsBytes(), before[0]);
    expect(await pending.readAsBytes(), before[1]);
  });

  test('unsupported delete targets preflight whole batch before deleting any generation', () async {
    final safe = await fixture('safe-game', '2020.02.29');
    final future = await fixture('future-game', '2021.01.01', version: 99);
    final safeBackup = File('${safe.path}.previous');
    await safeBackup.writeAsString(await safe.readAsString());
    final futureBackup = File('${future.path}.previous');
    await futureBackup.writeAsString(await safe.readAsString());
    final files = [safe, safeBackup, future, futureBackup];
    final before = await Future.wait(files.map((f) => f.readAsBytes()));
    for (final action in [
      () => store.delete('future-game'),
      () => store.deleteMany(['safe-game', 'future-game']),
    ]) {
      await expectLater(
        action(),
        throwsA(isA<UnsupportedSessionFormatException>()),
      );
      for (var i = 0; i < files.length; i++) {
        expect(await files[i].readAsBytes(), before[i]);
      }
    }
  });

  for (final nestedReview in [false, true]) {
    test(
      'future ${nestedReview ? 'review activeGame' : 'game'} schema preserves every generation',
      () async {
        final futureData = nestedReview
            ? <String, Object?>{
                'schema': 1,
                'type': 'review',
                'activeGame': {...game('2020.02.29'), 'schema': 2},
                'session': {'pgn': '*'},
              }
            : <String, Object?>{...game('2020.02.29'), 'schema': 2};
        final active = await fixture(
          'inner-future',
          null,
          active: true,
          data: futureData,
        );
        final archive = await fixture('inner-future', null, data: futureData);
        final previous = File('${active.path}.previous');
        await previous.writeAsString(
          jsonEncode({
            'version': 1,
            'id': 'inner-future',
            'data': game('2019.01.01'),
          }),
        );
        final files = [active, previous, archive];
        final before = await Future.wait(
          files.map((file) => file.readAsBytes()),
        );
        for (final action in [
          () => store.load(),
          () => store.save(game('2024.01.01')),
          () => store.startNew(),
          () => store.open('inner-future'),
          () => store.delete('inner-future'),
        ]) {
          await expectLater(
            action(),
            throwsA(isA<UnsupportedSessionFormatException>()),
          );
          for (var i = 0; i < files.length; i++) {
            expect(await files[i].readAsBytes(), before[i]);
          }
        }
      },
    );
  }

  for (final futureHistory in [false, true]) {
    for (final backupOnly in [false, true]) {
      test(
        'future ${futureHistory ? 'history' : 'envelope'} ${backupOnly ? 'backup' : 'primary'} blocks reads and writes without changing files',
        () async {
          final primary = await fixture(
            'protected',
            '2020.02.29',
            active: true,
            version: futureHistory ? 1 : 99,
            history: futureHistory
                ? {'version': 99, 'playedOn': '2020-02-29', 'startedAt': null}
                : null,
          );
          final previous = File('${primary.path}.previous');
          if (backupOnly) {
            await primary.rename(previous.path);
            await primary.writeAsString('{broken');
          } else {
            await previous.writeAsString(
              jsonEncode({
                'version': 1,
                'id': 'protected',
                'data': game('2019.01.01'),
              }),
            );
          }
          final before = [
            await primary.readAsBytes(),
            await previous.readAsBytes(),
          ];
          for (final action in [
            () => store.load(),
            () => store.save(game('2024.01.01')),
            () => store.startNew(),
            () => store.discardActive(),
          ]) {
            await expectLater(
              action(),
              throwsA(isA<UnsupportedSessionFormatException>()),
            );
            expect(await primary.readAsBytes(), before[0]);
            expect(await previous.readAsBytes(), before[1]);
          }
          SharedPreferences.setMockInitialValues({
            'activeSessionV1': jsonEncode(game('2024.01.01')),
          });
          final prefs = await SharedPreferences.getInstance();
          await expectLater(
            ActiveSessionStore.restoreOrMigrate(store, prefs),
            throwsA(isA<UnsupportedSessionFormatException>()),
          );
          expect(prefs.getString('activeSessionV1'), isNotNull);
          expect(await primary.readAsBytes(), before[0]);
          expect(await previous.readAsBytes(), before[1]);
        },
      );
    }
  }
}
