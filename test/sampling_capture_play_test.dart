import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:dartchess/dartchess.dart' as dc;

import 'fixtures/launch_game.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sampling_replay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late SamplingCapture capture;
  late Completer<Float32List> response;
  var calls = 0;
  setUp(() async {
    MaiaInferenceQueue.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'temperatureV2': 0.0,
      'topPV2': 0.0,
    });
    dir = await Directory.systemTemp.createTemp('maia-capture-play-');
    capture = SamplingCapture(directory: dir);
    SamplingCapture.instance = capture;
    await capture.setEnabled(true);
    await ActiveSessionStore.clear();
    response = Completer<Float32List>();
    calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (call) async {
          if (call.method == 'predict') {
            calls++;
            return response.future;
          }
          return null;
        });
  });
  tearDown(() async {
    if (!response.isCompleted) response.complete(Float32List(4352));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // Each case drains capture inside its own (possibly fake-clock) zone.
    capture.dispose();
    SamplingCapture.instance = SamplingCapture();
    await dir.delete(recursive: true);
    await ActiveSessionStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });
  Future<void> start(WidgetTester tester) async {
    final game = chess.Chess()..move('e4');
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          startingFen: game.fen,
          startingSide: PlayerSide.white,
          startingUseMoveHistory: true,
          startingPositionHistory: [chess.Chess.DEFAULT_POSITION, game.fen],
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 50 && calls == 0; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expectSync(calls, 1);
  }

  Future<void> drive(
    WidgetTester tester,
    Future<void> Function() operation,
  ) async {
    var done = false;
    Object? error;
    unawaited(
      operation().then(
        (_) => done = true,
        onError: (Object e) {
          error = e;
          done = true;
        },
      ),
    );
    for (var i = 0; i < 200 && !done; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expectSync(done, true, reason: 'filesystem operation completed');
    if (error != null) throw error!;
  }

  Future<void> drain(WidgetTester tester) async {
    var done = false;
    unawaited(capture.flush().then((_) => done = true));
    for (var i = 0; i < 100 && !done; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expectSync(done, true);
  }

  testWidgets(
    'normal play path records effective history, commit, and resume identity',
    (tester) async {
      await start(tester);
      response.complete(Float32List(4352));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pumpAndSettle();
      await drain(tester);
      await drive(tester, () async {
        final record = (await readExport(capture)).single;
        expectSync(record['outcome'], 'committed');
        expectSync(record['cache'], 'no-play-policy-cache');
        expectSync(record['historyEnabled'], true);
        expectSync(record['continuationPrefix'], [
          chess.Chess.DEFAULT_POSITION,
        ]);
        expectSync(record['sampling']['mode'], 'argmax');
        expectSync(record['queueOutcome'], 'inference-returned');
        replay(record);
        final saved = await ActiveSessionStore.load();
        expectSync(saved!['samplingGameId'], record['gameId']);
      });
      final initial = (await ActiveSessionStore.load())!;
      final id = initial['samplingGameId'];
      final startedAt = initial['samplingStartedAt'];
      expectSync(DateTime.parse(startedAt as String).isUtc, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      final resumed = (await ActiveSessionStore.load())!;
      expectSync(resumed['samplingGameId'], id);
      expectSync(resumed['samplingStartedAt'], startedAt);
      expectSync(calls, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  for (final side in ['w', 'b']) {
    for (final number in [5, 6, 20]) {
      testWidgets(
        'opening variety capture uses actual settings: $side move $number',
        (tester) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('maxOpeningVarietyV1', true);
          final fen =
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR $side KQkq - 0 $number';
          await tester.pumpWidget(
            MaterialApp(
              home: GamePage(
                startingFen: fen,
                startingSide: side == 'w' ? PlayerSide.black : PlayerSide.white,
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (var i = 0; i < 50 && calls == 0; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump();
          }
          expect(calls, 1);
          response.complete(Float32List(4352));
          await tester.pumpAndSettle();
          await drain(tester);
          await drive(tester, () async {
            final record = (await readExport(capture)).single;
            final sampling = record['sampling'] as Map;
            expectSync(record['outcome'], 'committed');
            expectSync(
              sampling['effectiveTemperature'],
              number <= 5 ? 1.0 : 0.0,
            );
            expectSync(sampling['effectiveTopP'], number <= 5 ? 1.0 : 0.0);
            expectSync(sampling['configuredTemperature'], 0.0);
            expectSync(sampling['configuredTopP'], 0.0);
            expectSync(sampling['openingVarietyApplied'], number <= 5);
            expectSync(sampling['fullMoveNumber'], number);
            final report = SamplingReportDecision.fromJson(
              Map<String, dynamic>.from(record),
            );
            expectSync(report.temperature, number <= 5 ? 1.0 : 0.0);
            expectSync(report.topP, number <= 5 ? 1.0 : 0.0);
            expectSync(report.played, isNotNull);
            if (number > 5) expectSync(report.played!.probability, 1.0);
            expectSync(sampling['mode'], number <= 5 ? 'random' : 'argmax');
            replay(record);
          });
          final saved = (await ActiveSessionStore.load())!;
          expect(
            saved['maiaSampling'],
            const MaiaPlaySettings(
              temperature: 0,
              topP: 0,
              maxOpeningVariety: true,
            ).toJson(),
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await prefs.setDouble('temperatureV2', 0.5);
          await prefs.setDouble('topPV2', 0.95);
          await prefs.setBool('maxOpeningVarietyV1', false);
          await tester.pumpWidget(const MaterialApp(home: GamePage()));
          await tester.pumpAndSettle();
          expect(
            (await ActiveSessionStore.load())!['maiaSampling'],
            saved['maiaSampling'],
          );
          expect(calls, 1);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await drain(tester);
        },
      );
    }
  }

  for (final savedProfile in [false, true]) {
    for (final number in [5, 6]) {
      testWidgets(
        'resumed inference honors ${savedProfile ? "saved" : "legacy"} profile at move $number',
        (tester) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('maxOpeningVarietyV1', true);
          final fen =
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 $number';
          await ActiveSessionStore.save({
            ...gameRecord(
              pgn: AnalysisSession.fromFen(fen).pgn,
              preset: 'unlimited',
            ),
            'clockPaused': false,
            if (savedProfile)
              'maiaSampling': const MaiaPlaySettings(
                temperature: 0.5,
                topP: 0.95,
                maxOpeningVariety: true,
              ).toJson(),
          });
          await tester.pumpWidget(const MaterialApp(home: GamePage()));
          await tester.pumpAndSettle();
          for (var i = 0; i < 50 && calls == 0; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump();
          }
          expect(calls, 1);
          response.complete(Float32List(4352));
          await tester.pumpAndSettle();
          await drain(tester);
          await drive(tester, () async {
            final record = (await readExport(capture)).single;
            final sampling = record['sampling'] as Map;
            expectSync(record['outcome'], 'committed');
            expectSync(
              sampling['effectiveTemperature'],
              !savedProfile
                  ? 0.0
                  : number <= 5
                  ? 1.0
                  : 0.5,
            );
            expectSync(
              sampling['effectiveTopP'],
              !savedProfile
                  ? 0.0
                  : number <= 5
                  ? 1.0
                  : 0.95,
            );
            expectSync(sampling['maxOpeningVariety'], savedProfile);
            replay(record);
          });
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await drain(tester);
        },
      );
    }
  }

  for (final resign in [false, true]) {
    testWidgets(
      'game summary records ${resign ? 'resignation' : 'final human checkmate'}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              startingFen: '7k/p7/5KQ1/8/8/8/8/8 b - - 0 1',
              startingSide: PlayerSide.white,
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 50 && calls == 0; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        expectSync(calls, 1);
        response.complete(
          Float32List(4352)..[MaiaEncoding.moveIndex('a7a6', true)] = 100,
        );
        await tester.pumpAndSettle();
        await drain(tester);
        // An already captured game's result remains accurate after opting out.
        await drive(tester, () => capture.setEnabled(false));
        if (resign) {
          await tester.tap(find.byKey(const ValueKey('quick-resign-button')));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Resign'));
        } else {
          boardOf(tester).onMove!(dc.NormalMove.fromUci('g6g7'));
        }
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await drain(tester);
        await drive(tester, () async {
          final savedResult = (await ActiveSessionStore.load())!;
          expectSync(savedResult['recentState'], 'completed');
          expectSync(capture.failed, false);
          expectSync(
            savedResult['samplingGameId'],
            (await readExport(capture)).single['gameId'],
          );
          final record = (await readExport(capture)).single;
          final exported = await capture.export();
          final manifest =
              jsonDecode((await exported.readAsLines()).first) as Map;
          final summary = manifest['games'][record['gameId']] as Map;
          expectSync(summary['result'], resign ? '0-1' : '1-0');
          expectSync(summary['playerIsWhite'], true);
          final saved = (await ActiveSessionStore.load())!;
          expectSync(summary['elo'], saved['elo']);
          expectSync(summary['startedAt'], saved['samplingStartedAt']);
          expectSync(summary['timeControl'], '-');
        });
        expectSync(calls, 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'disposing play during inference records stale output, never a committed move',
    (tester) async {
      await start(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      response.complete(Float32List(4352));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pumpAndSettle();
      await drain(tester);
      await drive(tester, () async {
        final record = (await readExport(capture)).single;
        expectSync(record['outcome'], 'cancelled-or-stale');
        expectSync(record.containsKey('committedMove'), false);
        expectSync(record['logits'], isNotNull);
        expectSync(record.containsKey('sampling'), false);
      });
    },
  );
  for (final invalid in [Float32List(3), Float32List(4352)..[3] = double.nan]) {
    testWidgets(
      'malformed/non-finite policy does not sample or commit (${invalid.length})',
      (tester) async {
        await start(tester);
        response.complete(invalid);
        await tester.pumpAndSettle();
        await drain(tester);
        await drive(tester, () async {
          final record = (await readExport(capture)).single;
          expectSync(record['outcome'], 'invalid-output');
          expectSync(record.containsKey('committedMove'), false);
          expectSync(record.containsKey('sampling'), false);
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'takeback and a different branch keep game identity but reject old inference',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            startingFen: chess.Chess.DEFAULT_POSITION,
            startingSide: PlayerSide.white,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 50; i++) {
        if ((await ActiveSessionStore.load())?['clockPaused'] == false) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expectSync((await ActiveSessionStore.load())?['clockPaused'], false);
      boardOf(tester).onMove!(dc.NormalMove.fromUci('e2e4'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 50 && calls < 1; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expectSync((await ActiveSessionStore.load())!['uciMoves'], ['e2e4']);
      expectSync(calls, 1);
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Takeback'));
      await tester.pumpAndSettle();
      response.complete(Float32List(4352));
      await tester.pumpAndSettle();
      await drain(tester);
      response = Completer<Float32List>();
      boardOf(tester).onMove!(dc.NormalMove.fromUci('d2d4'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 50 && calls < 2; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expectSync(calls, 2);
      response.complete(Float32List(4352));
      await tester.pumpAndSettle();
      await drain(tester);
      await drive(tester, () async {
        final records = await readExport(capture);
        expectSync(records, hasLength(2));
        expectSync(records[0]['outcome'], 'cancelled-or-stale');
        expectSync(records[1]['outcome'], 'committed');
        expectSync(records[0]['gameId'], records[1]['gameId']);
        expectSync(records[0]['requestId'], isNot(records[1]['requestId']));
        expectSync(records[0]['generation'], isNot(records[1]['generation']));
        final afterD4 = chess.Chess()..move('d4');
        expectSync(records[1]['positions'], [
          chess.Chess.DEFAULT_POSITION,
          afterD4.fen,
        ]);
        replay(records[1]);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  test('queue cancellation and timeout preserve request association', () async {
    final scope = MaiaInferenceScope();
    final fen = chess.Chess.DEFAULT_POSITION;
    CapturedDecision ticket() => capture.begin(
      gameId: SamplingCapture.newId(),
      generation: 0,
      ply: 0,
      fen: fen,
      positions: [fen],
      prefix: [],
      history: false,
      elo: 1600,
      tokens: Float32List(6208),
      backend: 'test',
    )!;
    final a = ticket();
    final b = ticket();
    // Keep inference occupied so both replaceable requests are pending.
    final blockerResponse = response;
    final blocker = MaiaInferenceQueue.predict({
      'tokens': Float32List(6208),
      'selfElo': 1600,
      'opponentElo': 1600,
    });
    await Future<void>.delayed(Duration.zero);
    response = Completer<Float32List>();
    final first = MaiaInferenceQueue.predict(
      {'tokens': Float32List(6208), 'selfElo': 1600, 'opponentElo': 1600},
      replaceableScope: scope,
      capture: a,
    );
    final second = MaiaInferenceQueue.predict(
      {'tokens': Float32List(6208), 'selfElo': 1600, 'opponentElo': 1600},
      replaceableScope: scope,
      capture: b,
      timeout: const Duration(milliseconds: 10),
    );
    blockerResponse.complete(Float32List(4352));
    await blocker;
    expectSync(await first, isNull);
    a.finish('cancelled-or-stale');
    await expectLater(second, throwsA(isA<TimeoutException>()));
    b.finish('timeout');
    response.complete(Float32List(4352));
    await capture.flush();
    final records = await readExport(capture);
    final cancelled = records.singleWhere(
      (r) => r['requestId'] == a.data['requestId'],
    );
    final timedOut = records.singleWhere(
      (r) => r['requestId'] == b.data['requestId'],
    );
    expectSync(cancelled['queueOutcome'], 'cancelled-before-inference');
    expectSync(timedOut['outcome'], 'timeout');
    expectSync(records.every((r) => !r.containsKey('committedMove')), true);
  });
}
