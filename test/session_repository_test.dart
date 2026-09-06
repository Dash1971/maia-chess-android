import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  late Directory directory;
  late SessionRepository store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('maia-sessions-');
    store = SessionRepository(directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'writes are ordered and snapshots detach nested mutable lists',
    () async {
      final moves = <String>['e4'];
      final first = store.save({'type': 'game', 'moves': moves});
      moves.add('e5');
      final second = store.save({'type': 'game', 'moves': moves});
      moves.clear();
      await Future.wait([first, second]);
      expect((await store.load())!['moves'], ['e4', 'e5']);
      await File('${directory.path}/active.json').writeAsString('{broken');
      expect((await store.load())!['moves'], ['e4']);
    },
  );

  test(
    'interrupted rename recovers previous checkpoint across a restart',
    () async {
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      await File('${directory.path}/active.json')
          .rename('${directory.path}/active.json.previous');
      await File('${directory.path}/active.json.pending')
          .writeAsString('{partial');
      final restarted = SessionRepository(directory);
      expect((await restarted.load())!['pgn'], '1. e4 *');
      await restarted.save({'type': 'game', 'pgn': '1. e4 e5 *'});
      await File('${directory.path}/active.json').writeAsString('bad');
      expect((await restarted.load())!['pgn'], '1. e4 *');
    },
  );

  test(
    'analysis sessions are excluded while games remain reopenable',
    () async {
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      final first = (await store.recent()).single.id;
      await store.startNew();
      expect(await SessionRepository(directory).load(), isNull);
      await store.save({'type': 'analysis', 'pgn': '1. d4 *'});
      final entries = await store.recent();
      expect(entries.map((entry) => entry.id), [first]);
      expect((await store.open(first))!['pgn'], '1. e4 *');
      expect((await store.recent()).single.id, first);
    },
  );

  test('live checkpoints restore but do not appear in Recent games', () async {
    await store.save({
      'type': 'game',
      'recentState': 'active',
      'pgn': '[Result "*"]\n\n1. e4 *',
    });

    expect((await store.load())!['pgn'], contains('e4'));
    expect(await store.recent(), isEmpty);
    await store.startNew();
    expect(await store.recent(), isEmpty);
  });

  test('incomplete games convert to completed without duplication', () async {
    await store.save({
      'type': 'game',
      'recentState': 'incomplete',
      'pgn': '[Result "*"]\n\n1. e4 *',
    });
    final incomplete = (await store.recent()).single;
    expect(incomplete.isIncomplete, isTrue);
    await store.startNew();
    await store.open(incomplete.id);
    await store.save({
      'type': 'game',
      'recentState': 'completed',
      'pgn': '[Result "1-0"]\n\n1. e4 e5 1-0',
    });

    final completed = (await store.recent()).single;
    expect(completed.id, incomplete.id);
    expect(completed.isIncomplete, isFalse);
    expect(completed.data['pgn'], contains('1-0'));
  });

  test('review checkpoints expose only their saved game', () async {
    await store.save({
      'type': 'review',
      'activeGame': {
        'type': 'game',
        'recentState': 'completed',
        'pgn': '[Result "0-1"]\n\n0-1',
      },
      'session': {'pgn': '[Result "*"]\n\n*'},
    });

    final recent = (await store.recent()).single;
    expect(recent.data['type'], 'game');
    await store.startNew();
    final reopened = await store.open(recent.id);
    expect(reopened!['type'], 'game');
    expect(reopened['pgn'], contains('0-1'));
  });

  test('bulk deletion removes selected games and recovery files', () async {
    await store.save({'type': 'game', 'pgn': '1. e4 *'});
    final first = (await store.recent()).single.id;
    await store.startNew();
    await store.save({'type': 'game', 'pgn': '1. d4 *'});
    final all = await store.recent();
    final second = all.firstWhere((entry) => entry.id != first).id;

    await store.deleteMany([first, second]);

    expect(await store.recent(), isEmpty);
    expect(await store.load(), isNull);
    for (final id in [first, second]) {
      expect(await File('${directory.path}/games/$id.json').exists(), isFalse);
      expect(
        await File('${directory.path}/games/$id.json.previous').exists(),
        isFalse,
      );
    }
  });

  test(
    'deleting an active session removes its backups without resurrection',
    () async {
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      await store.save({'type': 'game', 'pgn': '1. e4 e5 *'});
      final id = (await store.recent()).single.id;
      await store.open(id);
      await store.delete(id);
      final restarted = SessionRepository(directory);
      expect(await restarted.load(), isNull);
      expect(await restarted.recent(), isEmpty);
    },
  );

  test(
    'discarding the active game does not leave it in Recent games',
    () async {
      await store.save({'type': 'game', 'pgn': '1. d4 d5 *'});
      final id = (await store.recent()).single.id;
      await store.startNew();
      await store.open(id);

      await store.discardActive();

      final restarted = SessionRepository(directory);
      expect(await restarted.load(), isNull);
      expect(await restarted.recent(), isEmpty);
    },
  );

  test(
    'deleting an archived session removes every recovery generation',
    () async {
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      final id = (await store.recent()).single.id;
      await store.startNew();
      await store.open(id);
      await store.startNew();
      final archive = File('${directory.path}/games/$id.json');
      expect(await archive.exists(), isTrue);
      expect(await File('${archive.path}.previous').exists(), isTrue);

      await store.delete(id);

      expect(await archive.exists(), isFalse);
      expect(await File('${archive.path}.previous').exists(), isFalse);
      expect(await File('${archive.path}.pending').exists(), isFalse);
      expect(await SessionRepository(directory).recent(), isEmpty);
    },
  );

  test(
    'archived backups remain available when their primary file is corrupt',
    () async {
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      final id = (await store.recent()).single.id;
      await store.open(id);
      await store.startNew();
      await File('${directory.path}/games/$id.json').writeAsString('bad');
      expect((await store.recent()).single.data['pgn'], '1. e4 *');
      expect((await store.open(id))!['pgn'], '1. e4 *');
    },
  );
  test('migration is durable before removing the old preference', () async {
    final legacy = {'schema': 1, 'type': 'game', 'pgn': '1. e4 *'};
    SharedPreferences.setMockInitialValues({
      'activeSessionV1': jsonEncode(legacy),
    });
    final preferences = await SharedPreferences.getInstance();
    expect(
      await ActiveSessionStore.restoreOrMigrate(store, preferences),
      legacy,
    );
    expect(preferences.getString('activeSessionV1'), isNull);
    expect(await SessionRepository(directory).load(), legacy);
  });

  test('interrupted migration cannot resurrect an archived game', () async {
    final legacy = {'schema': 1, 'type': 'game', 'pgn': '1. e4 *'};
    SharedPreferences.setMockInitialValues({
      'activeSessionV1': jsonEncode(legacy),
    });
    // Simulate process death after the new file is durable but before the old
    // preference was removed, followed by a successful Home operation.
    await store.save(legacy);
    await store.startNew();
    final preferences = await SharedPreferences.getInstance();
    expect(
      await ActiveSessionStore.restoreOrMigrate(
        SessionRepository(directory),
        preferences,
      ),
      isNull,
    );
    expect(preferences.getString('activeSessionV1'), isNull);
    expect((await store.recent()).single.data, legacy);
  });

  testWidgets(
    'Recent games supports multi-select, select all, and delete all',
    (tester) async {
      final games = <RecentSession>[
        RecentSession('first', DateTime.utc(2026, 9, 5), {
          'type': 'game',
          'recentState': 'incomplete',
          'elo': 500,
          'pgn': '[Event "First"]\n[Result "*"]\n\n*',
        }),
        RecentSession('second', DateTime.utc(2026, 9, 4), {
          'type': 'game',
          'recentState': 'completed',
          'elo': 1500,
          'pgn': '[Event "Second"]\n[Result "1-0"]\n\n1-0',
        }),
        RecentSession('third', DateTime.utc(2026, 9, 3), {
          'type': 'game',
          'recentState': 'completed',
          'elo': 2000,
          'pgn': '[Event "Third"]\n[Result "0-1"]\n\n0-1',
        }),
      ];
      final deletionBatches = <Set<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RecentGamesPage(
            loadGames: () async => List.of(games),
            deleteGames: (ids) async {
              final deleted = ids.toSet();
              deletionBatches.add(deleted);
              games.removeWhere((game) => deleted.contains(game.id));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Incomplete · 2026-09-05'), findsOneWidget);
      expect(find.textContaining('Completed · 2026-09-04'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('recent-games-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Delete all games'), findsOneWidget);
      await tester.tap(find.text('Select games'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      expect(find.text('3 selected'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      expect(find.text('0 selected'), findsOneWidget);
      await tester.tap(find.text('First'));
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-selected-games')));
      await tester.pumpAndSettle();
      expect(find.text('Delete 2 games?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deletionBatches.single, {'first', 'second'});
      expect(find.text('Third'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recent-games-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete all games'));
      await tester.pumpAndSettle();
      expect(find.text('Delete saved game?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deletionBatches.last, {'third'});
      expect(
        find.textContaining('Completed games and incomplete games'),
        findsOneWidget,
      );
    },
  );
}
