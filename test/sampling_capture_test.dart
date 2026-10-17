import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sampling_replay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late SamplingCapture store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('maia-capture-test-');
    store = SamplingCapture(directory: dir);
    await store.setEnabled(true);
  });
  tearDown(() async {
    await store.flush();
    store.dispose();
    await dir.delete(recursive: true);
  });
  CapturedDecision begin({
    String? id,
    List<String>? positions,
    bool history = false,
    Float32List? tokens,
  }) {
    final p = positions ?? [chess.Chess.DEFAULT_POSITION];
    return store.begin(
      gameId: id ?? SamplingCapture.newId(),
      generation: 3,
      ply: p.length - 1,
      fen: p.last,
      positions: p,
      prefix: const [],
      history: history,
      elo: 1600,
      tokens:
          tokens ?? MaiaEncoding.historicalTokens(p, useMoveHistory: history),
      backend: 'test',
    )!;
  }

  test(
    'latest ten games, resume order, eviction watermark and clear',
    () async {
      final ids = <String>[];
      for (var n = 0; n < 12; n++) {
        final id = SamplingCapture.newId();
        ids.add(id);
        begin(id: id).finish('cancelled-or-stale');
        await store.flush();
      }
      final expected = ids.skip(2).toList().reversed.toList();
      expect(
        (await readExport(store)).map((r) => r['gameId']).toList(),
        expected,
      );
      expect(store.prunedGames, 2);
      // A retained resumed game stays in its original place and retains both attempts.
      begin(id: ids[3]).finish('cancelled-or-stale');
      await store.flush();
      final resumed = await readExport(store);
      expect(resumed.map((r) => r['gameId']).toSet().toList(), expected);
      expect(resumed.where((r) => r['gameId'] == ids[3]), hasLength(2));
      // Neither resuming nor metadata can recreate a game removed by retention.
      begin(id: ids.first).finish('cancelled-or-stale');
      store.updateGame(ids.first, {'result': '1-0'});
      await store.flush();
      expect(
        (await readExport(store)).map((r) => r['gameId']).toSet().toList(),
        expected,
      );
      expect(store.failed, isFalse);
      await store.clear();
      begin(id: ids.first).finish('cancelled-or-stale');
      await store.flush();
      expect((await readExport(store)).single['gameId'], ids.first);
    },
  );

  test(
    'load immediately enforces ten games on a previously larger store',
    () async {
      store.dispose();
      store = SamplingCapture(directory: dir, limitGames: 12);
      await store.setEnabled(true);
      for (var i = 0; i < 12; i++) {
        begin().finish('cancelled-or-stale');
        await store.flush();
      }
      store.dispose();
      store = SamplingCapture(directory: dir);
      await store.loadStoredData();
      expect(await readExport(store), hasLength(10));
      expect(store.prunedGames, 2);
    },
  );

  test('loading data and enabling recording share storage preparation', () async {
    await store.setEnabled(false);
    final pending = SamplingCapture();
    final reachedMetadata = Completer<void>();
    final metadata = Completer<Map<String, Object?>>();
    var metadataCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (call) async {
          if (call.method == 'dataDirectory') return dir.path;
          if (call.method == 'samplingMetadata') {
            metadataCalls++;
            if (!reachedMetadata.isCompleted) reachedMetadata.complete();
            return metadata.future;
          }
          return null;
        });
    try {
      await pending.initialize();
      final load = pending.loadStoredData();
      await reachedMetadata.future;
      final enable = pending.setEnabled(true);
      // Drain the preference write while metadata deliberately remains blocked.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(pending.enabled, isTrue);
      expect(metadataCalls, 1);
      metadata.complete({'backend': 'test'});
      await Future.wait([load, enable]);
      expect(pending.failed, isFalse);
      expect(pending.hasStorage, isTrue);
      expect(pending.records, 0);
      await pending.loadStoredData();
      expect(metadataCalls, 1);
    } finally {
      if (!metadata.isCompleted) metadata.complete({'backend': 'test'});
      await pending.flush();
      pending.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, null);
    }
  });

  test(
    'metadata survives restart and a stale final ticket cannot erase result',
    () async {
      final id = SamplingCapture.newId();
      final ticket = store.begin(
        gameId: id,
        generation: 0,
        ply: 0,
        fen: chess.Chess.DEFAULT_POSITION,
        positions: [chess.Chess.DEFAULT_POSITION],
        prefix: [],
        history: false,
        elo: 1600,
        tokens: Float32List(6208),
        backend: 'test',
        game: {
          'startedAt': '2026-10-14T01:00:00Z',
          'result': '*',
          'playerIsWhite': false,
          'elo': 1600,
        },
      );
      store.updateGame(id, {
        'startedAt': '2026-10-15T01:00:00Z',
        'result': '0-1',
        'playerIsWhite': false,
        'elo': 1600,
      });
      ticket!.finish('cancelled-or-stale');
      await store.flush();
      store.dispose();
      store = SamplingCapture(directory: dir);
      await store.loadStoredData();
      final manifest =
          jsonDecode((await (await store.export()).readAsLines()).first) as Map;
      expect(manifest['games'][id]['result'], '0-1');
      expect(manifest['games'][id]['startedAt'], '2026-10-14T01:00:00Z');
      expect(manifest['gameOrder'], 'newest-first');
      final report = await SamplingReport.read(await store.export());
      expect(report.summaries[id]!['result'], '0-1');
      expect(store.failed, isFalse);
    },
  );

  test(
    'export replay and capture parity: colors, promotions, history, settings',
    () async {
      store.dispose();
      store = SamplingCapture(directory: dir, limitGames: 100);
      await store.setEnabled(true);
      final black = chess.Chess()..move('e4');
      final histories = [
        [chess.Chess.DEFAULT_POSITION],
        [chess.Chess.DEFAULT_POSITION, black.fen],
        ['7k/P7/8/8/8/8/8/7K w - - 0 1'],
        ['7k/8/8/8/8/8/p7/7K b - - 0 1'],
      ];
      for (final positions in histories) {
        for (final history in [false, true]) {
          for (final settings in [
            (1.0, 1.0),
            (0.5, 0.9),
            (0.0, 0.0),
            (1.0, 0.0),
          ]) {
            for (final draw in [0.0, 0.513, 0.999999999999]) {
              final board = chess.Chess.fromFEN(positions.last);
              final moves = board.moves({'asObjects': true}).cast<chess.Move>();
              final logits = Float32List.fromList(
                List.generate(4352, (i) => sin(i.toDouble()) * 4),
              );
              final ticket = begin(positions: positions, history: history);
              ticket.output(logits);
              final a = Draw(draw);
              final b = Draw(draw);
              final plain = MaiaEncoding.sampleLegalMove(
                board,
                moves,
                logits,
                temperature: settings.$1,
                topP: settings.$2,
                random: a,
              );
              final logged = MaiaEncoding.sampleLegalMove(
                board,
                moves,
                logits,
                temperature: settings.$1,
                topP: settings.$2,
                random: b,
                onSample: ticket.sampling,
              );
              expect(MaiaEncoding.uci(logged), MaiaEncoding.uci(plain));
              expect(a.calls, b.calls);
              expect(b.calls, settings.$1 == 0 ? 0 : 1);
              board.move(logged);
              ticket.finish(
                'committed',
                move: MaiaEncoding.uci(logged),
                committedFen: board.fen,
              );
              await store.flush();
              expect(store.failed, isFalse);
            }
          }
        }
      }
      final records = await readExport(store);
      expect(records, hasLength(96));
      for (final record in records) {
        replay(record);
      }
    },
  );
  test('Qf5 rare tail is captured and independently replayed', () async {
    final fixture = jsonDecode(
      await File('test/fixtures/sampling/qf5.json').readAsString(),
    ) as Map;
    final positions = (fixture['history'] as List).cast<String>();
    final raw = ByteData.sublistView(base64Decode(fixture['logits']));
    final logits = Float32List.fromList(
      List.generate(4352, (i) => raw.getFloat32(i * 4, Endian.little)),
    );
    final board = chess.Chess.fromFEN(fixture['fen']);
    final moves = board.moves({'asObjects': true}).cast<chess.Move>();
    Map<String, Object?>? probe;
    MaiaEncoding.sampleLegalMove(
      board,
      moves,
      logits,
      random: Draw(0.5),
      onSample: (v) => probe = v,
    );
    final random = probe!['random'] as Map;
    final order = random['weightedOrder'] as List;
    var lower = 0.0;
    var weight = 0.0;
    for (final item in order) {
      if (item['uci'] == fixture['target']) {
        weight = item['weight'];
        break;
      }
      lower += item['weight'] as double;
    }
    final draw = (lower + weight / 2) / (random['total'] as double);
    final ticket = begin(positions: positions, history: true);
    ticket.output(logits);
    final move = MaiaEncoding.sampleLegalMove(
      board,
      moves,
      logits,
      random: Draw(draw),
      onSample: ticket.sampling,
    );
    expect(MaiaEncoding.uci(move), 'h5f5');
    board.move(move);
    ticket.finish('committed', move: 'h5f5', committedFen: board.fen);
    await store.flush();
    final record = (await readExport(store)).single;
    replay(record);
    final probability = (record['rawLegalPolicy'] as List).singleWhere(
      (p) => p['uci'] == 'h5f5',
    )['probability'];
    expect(probability, closeTo(0.0004019, 0.000001));
  });
  test(
    'oldest game is evicted as a whole, recent game records retained',
    () async {
      store.dispose();
      store = SamplingCapture(directory: dir, limitBytes: 80000);
      await store.setEnabled(true);
      final first = SamplingCapture.newId();
      final second = SamplingCapture.newId();
      begin(id: first).finish('cancelled-or-stale');
      await store.flush();
      begin(id: first).finish('cancelled-or-stale');
      await store.flush();
      begin(id: second).finish('cancelled-or-stale');
      await store.flush();
      final records = await readExport(store);
      expect(records.map((r) => r['gameId']).toSet(), {second});
      expect(store.prunedGames, 1);
      expect(store.failed, isFalse);
    },
  );
  test('clear cannot be undone by a late result, off survives restart with retained data', () async {
    final pending = begin();
    await store.flush();
    await store.clear();
    pending.output(Float32List(4352));
    pending.finish('committed');
    await store.flush();
    expect(await readExport(store), isEmpty);
    begin().finish('timeout');
    await store.flush();
    await store.setEnabled(false);
    final restarted = SamplingCapture(directory: dir);
    await restarted.loadStoredData();
    expect(restarted.enabled, isFalse);
    expect(restarted.records, 1);
    expect((await readExport(restarted)).single['outcome'], 'timeout');
    restarted.dispose();
  });
  test('immutable snapshots and non-finite output preserve bits', () async {
    final tokens = MaiaEncoding.historicalTokens([
      chess.Chess.DEFAULT_POSITION,
    ]);
    final ticket = begin(tokens: tokens);
    tokens.fillRange(0, tokens.length, 42);
    final bytes = ByteData(8)
      ..setUint32(0, 0x7fc01234, Endian.host)
      ..setFloat32(4, double.infinity, Endian.host);
    final values = bytes.buffer.asFloat32List();
    ticket.output(values);
    values[1] = 0;
    ticket.finish('invalid-output');
    await store.flush();
    final record = (await readExport(store)).single;
    expect(floats(record['tokens']), encode(record['historyWindow']));
    final recorded = ByteData.sublistView(
      base64Decode(record['logits']['data']),
    );
    expect(recorded.getUint32(0, Endian.little), 0x7fc01234);
    expect(recorded.getFloat32(4, Endian.little), double.infinity);
    expect(record['outcome'], 'invalid-output');
    expect(record.containsKey('sampling'), isFalse);
  });
  test(
    'pending is explicitly incomplete and bounded queue reports losses',
    () async {
      for (var i = 0; i < 30; i++) {
        store.begin(
          gameId: SamplingCapture.newId(),
          generation: 0,
          ply: 0,
          fen: chess.Chess.DEFAULT_POSITION,
          positions: [chess.Chess.DEFAULT_POSITION],
          prefix: [],
          history: false,
          elo: 1600,
          tokens: Float32List(6208),
          backend: 'test',
        );
      }
      await store.flush();
      expect(store.dropped, greaterThan(0));
      final records = await readExport(store);
      expect(records.length, lessThanOrEqualTo(8));
      expect(
        records.every(
          (r) =>
              r['outcome'] == 'pending' &&
              r['coverage'] == 'captured-decisions-only',
        ),
        isTrue,
      );
    },
  );
  test('capture overhead measurement (host debug, not a phone benchmark)', () async {
    final board = chess.Chess();
    final moves = board.moves({'asObjects': true}).cast<chess.Move>();
    final logits = Float32List.fromList(
      List.generate(4352, (i) => sin(i.toDouble())),
    );
    final times = <String, double>{};
    for (final enabled in [false, true]) {
      final watch = Stopwatch()..start();
      for (var i = 0; i < 3000; i++) {
        MaiaEncoding.sampleLegalMove(
          board,
          moves,
          logits,
          random: Draw(0.4),
          onSample: enabled ? (_) {} : null,
        );
      }
      times[enabled ? 'traceMicroseconds' : 'plainMicroseconds'] =
          watch.elapsedMicroseconds / 3000;
    }
    var synchronous = 0;
    final wall = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      final watch = Stopwatch()..start();
      final ticket = begin();
      ticket.output(logits);
      MaiaEncoding.sampleLegalMove(
        board,
        moves,
        logits,
        random: Draw(0.4),
        onSample: ticket.sampling,
      );
      ticket.finish('cancelled-or-stale');
      synchronous += watch.elapsedMicroseconds;
      await store.flush();
    }
    expect(store.failed, false);
    times['captureSynchronousMicroseconds'] = synchronous / 50;
    times['captureIncludingDiskMilliseconds'] = wall.elapsedMilliseconds / 50;
    // Report observations, not a machine-dependent/flaky performance assertion.
    // ignore: avoid_print
    print('Sampling capture host timing: ${jsonEncode(times)}');
  });
  test('off is the default and enabling survives a new controller', () async {
    await store.setEnabled(false);
    await (await SharedPreferences.getInstance()).remove(
      samplingCapturePreference,
    );
    final off = SamplingCapture(directory: dir);
    await off.initialize();
    expect(off.enabled, false);
    expect(
      off.begin(
        gameId: SamplingCapture.newId(),
        generation: 0,
        ply: 0,
        fen: chess.Chess.DEFAULT_POSITION,
        positions: [chess.Chess.DEFAULT_POSITION],
        prefix: [],
        history: false,
        elo: 1600,
        tokens: Float32List(6208),
        backend: 'test',
      ),
      isNull,
    );
    await off.setEnabled(true);
    final restarted = SamplingCapture(directory: dir);
    await restarted.initialize();
    expect(restarted.enabled, true);
    off.dispose();
    restarted.dispose();
  });
  test(
    'a corrupted record fails export instead of silently omitting data',
    () async {
      begin().finish('timeout');
      await store.flush();
      final record = dir
          .listSync(recursive: true)
          .whereType<File>()
          .singleWhere(
            (f) => f.path.contains('/games/') && f.path.endsWith('.json'),
          );
      final envelope = jsonDecode(record.readAsStringSync()) as Map;
      envelope['record'] = '{}';
      record.writeAsStringSync(jsonEncode(envelope));
      await expectLater(store.export(), throwsFormatException);
      expect(store.records, 1);
    },
  );
  test('document picker lease survives settings navigation and preserves its snapshot', () async {
    begin().finish('timeout');
    await store.flush();
    final opened = Completer<void>();
    final picker = Completer<bool?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (call) async {
          if (call.method == 'saveSamplingData') {
            opened.complete();
            return picker.future;
          }
          return null;
        });
    try {
      final save = store.saveDocument();
      await opened.future;
      expect(store.busy, true);
      final original = await File('${dir.path}/export.jsonl').readAsString();
      await expectLater(store.saveDocument(), throwsStateError);
      expect(() => store.export(), throwsStateError);
      await store.clear();
      expect(store.records, 1);
      begin().finish('timeout');
      await store.flush();
      expect(await File('${dir.path}/export.jsonl').readAsString(), original);
      picker.complete(null);
      await save;
      expect(store.busy, false);
      expect(store.records, 2);
      expect(File('${dir.path}/export.jsonl').existsSync(), false);
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, null);
    }
  });
  test('readable sharing uses a verified report and releases its lease on platform failure', () async {
    begin().finish('timeout');
    await store.flush();
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    var called = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (call) async {
          if (call.method == 'saveSamplingData') {
            called = true;
            expect(store.busy, true);
            expect(call.arguments['share'], true);
            expect(call.arguments['readable'], true);
            final report = File('${dir.path}/report.html');
            expect(
              await report.readAsString(),
              contains('Not recorded as played'),
            );
            await store.clear();
            expect(store.records, 1);
            throw PlatformException(code: 'test_share_failed');
          }
          return null;
        });
    try {
      await expectLater(
        store.saveDocument(
          share: true,
          readable: true,
          text: samplingReportText(strings),
        ),
        throwsA(isA<PlatformException>()),
      );
      expect(called, true);
      expect(store.busy, false);
      expect(store.records, 1);
      expect(File('${dir.path}/export.jsonl').existsSync(), false);
      expect(File('${dir.path}/report.html').existsSync(), false);
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, null);
    }
  });
}
