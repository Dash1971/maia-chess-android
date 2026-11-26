import 'dart:convert';
import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

import 'recent_games_pgn_export_test.dart' show annotated, incomplete, setup;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late SessionRepository store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('maia-pgn-roundtrip-');
    store = SessionRepository(dir);
  });
  tearDown(() => dir.delete(recursive: true));

  Future<Map<String, String>> files() async => {
    await for (final entry in dir.list(recursive: true))
      if (entry is File) entry.path: base64Encode(await entry.readAsBytes()),
  };
  Future<String> exportAll() async {
    final games = await store.recent();
    return RecentGamesPgn.export(
      games.map((g) => g.id).toList(),
      store.readPgnForExport,
    );
  }

  test(
    'export re-import of raw stored PGNs skips all selected games',
    () async {
      final source = '$annotated\n\n$incomplete\n\n$setup';
      expect(
        (await store.importCollection(await PgnCollection.parse(source)))
            .imported,
        3,
      );
      final before = await files();
      final exported = await exportAll();
      expect(
        exported,
        isNot(source),
      ); // The public exporter reformats these PGNs.
      final result = await SessionRepository(dir)
          .importCollection(await PgnCollection.parse(exported));
      expect(result.imported, 0);
      expect(result.duplicates, 3);
      expect(await files(), before);
      expect(await store.recent(), hasLength(3));
    },
  );

  test(
    'export re-import of app-generated archived and current games skips both',
    () async {
      for (final move in ['e4', 'd4']) {
        final game = chess.Chess()..move(move);
        await store.save({
          'type': 'game',
          'pgn': game.pgn(),
          'recentState': 'completed',
        });
        if (move == 'e4') await store.startNew();
      }
      final before = await files();
      final result = await store.importCollection(
        await PgnCollection.parse(await exportAll()),
      );
      expect(result.imported, 0);
      expect(result.duplicates, 2);
      expect(await files(), before);
    },
  );

  test(
    'canonical export matches raw copies within the same incoming collection',
    () async {
      final exported = await RecentGamesPgn.export([
        'one',
        'two',
      ], (id) async => id == 'one' ? annotated : setup);
      final result = await store.importCollection(
        await PgnCollection.parse('$annotated\n$setup\n$exported'),
      );
      expect(result.imported, 2);
      expect(result.duplicates, 2);
      final repeat = await store.importCollection(
        await PgnCollection.parse(await exportAll()),
      );
      expect(repeat.imported, 0);
      expect(repeat.duplicates, 2);
    },
  );

  test('round-trip comparison retains changed annotations, metadata, clocks and variations', () async {
    await store.importCollection(
      await PgnCollection.parse('$annotated\n$setup'),
    );
    final changed = [
      annotated.replaceFirst('café', 'different note'),
      annotated.replaceFirst('0:04:58', '0:04:57'),
      annotated.replaceFirst('Sicilian', 'different variation note'),
      annotated.replaceFirst('1... c5', '1... e6'),
      annotated.replaceFirst('[White "Player"]', '[White "Another player"]'),
      annotated.replaceFirst('[Event', '[Source "Personal"]\n[Event'),
    ];
    final exported = await RecentGamesPgn.export(
      List.generate(changed.length, (i) => '$i'),
      (id) async => changed[int.parse(id)],
    );
    final result = await store.importCollection(
      await PgnCollection.parse(exported),
    );
    expect(result.imported, changed.length);
    expect(result.duplicates, 0);
    expect(await store.recent(), hasLength(changed.length + 2));
  });

  test(
    'line comments not represented by the exporter are never collapsed',
    () async {
      const withComment =
          '[Event "Line comment"]\n\n1. e4 ; personal note\ne5 *';
      const otherComment =
          '[Event "Line comment"]\n\n1. e4 ; another note\ne5 *';
      await store.importCollection(
        await PgnCollection.parse('$withComment\n$setup'),
      );
      final exported = await RecentGamesPgn.export([
        'one',
      ], (_) async => withComment);
      final result = await store.importCollection(
        await PgnCollection.parse('$exported\n$otherComment'),
      );
      // Losing an unsupported comment is a content difference, not a duplicate.
      expect(result.imported, 2);
      expect(result.duplicates, 0);
    },
  );

  test(
    'escaped headers and Unicode survive comparison after an export round trip',
    () async {
      const escaped = r'[Event "Quoted \"game\" \\ archive"]';
      final original = annotated.replaceFirst('[Event "Annotated"]', escaped);
      await store.importCollection(
        await PgnCollection.parse('$original\n$setup'),
      );
      final before = await files();
      final result = await store.importCollection(
        await PgnCollection.parse(await exportAll()),
      );
      expect(result.imported, 0);
      expect(result.duplicates, 2);
      expect(await files(), before);
    },
  );

  for (final entry in {
    'duplicate tags': '[Event "Personal"]\n$incomplete',
    'conflicting result': '[Event "Result"]\n[Result "0-1"]\n\n1. e4 e5 1-0',
    'escape line': '% private source information\n$incomplete',
  }.entries) {
    test(
      'serializer-discarded ${entry.key} is never treated as identical',
      () async {
        await store.importCollection(
          await PgnCollection.parse('${entry.value}\n$setup'),
        );
        final exported = await RecentGamesPgn.export([
          'one',
        ], (_) async => entry.value);
        final result = await store.importCollection(
          await PgnCollection.parse(exported),
        );
        expect(result.imported, 1);
        expect(result.duplicates, 0);
      },
    );
  }

  test('malformed legacy PGN cannot mask a valid empty game', () async {
    await store.save({
      'type': 'game',
      'pgn': 'not a PGN',
      'recentState': 'completed',
    });
    final result = await store.importCollection(
      await PgnCollection.parse('*\n\n$setup'),
    );
    expect(result.imported, 2);
    expect(result.duplicates, 0);
  });
}
