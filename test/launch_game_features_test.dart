import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';
import 'fixtures/electronic_board.dart';

void main() {
  String? copiedPgn;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    copiedPgn = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedPgn = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null),
  );

  for (final penalty in [false, true]) {
    for (final multiple in [false, true]) {
      for (final unlimited in [false, true]) {
        testWidgets(
          'premove penalty=$penalty multiple=$multiple unlimited=$unlimited',
          (tester) async {
            SharedPreferences.setMockInitialValues({
              'premovePenalty': penalty,
              'multiplePremoves': multiple,
            });
            final maia = ControlledMaia();
            await ActiveSessionStore.save(
              gameRecord(
                playerWhite: false,
                preset: unlimited ? 'unlimited' : 'blitz',
              ),
            );
            await tester.pumpWidget(
              MaterialApp(
                home: GamePage(
                  maiaEvaluator: maia.call,
                  clockFactory: () => TestClock(17),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(maia.requests.length, 1);
            await queueMove(tester, 'g8f6');
            if (multiple) await queueMove(tester, 'f6g4');
            maia.reply('e2e4');
            await tester.pumpAndSettle();
            var saved = await ActiveSessionStore.load();
            expect(saved!['uciMoves'], ['e2e4', 'g8f6']);
            final history = saved['clockHistory'] as List;
            expect(
              history[2],
              unlimited ? [5000, 5000] : [6983, penalty ? 6900 : 6983],
            );
            expect(maia.requests.length, 2);
            if (multiple) {
              expect(
                find.byKey(const ValueKey('premove-queue')),
                findsOneWidget,
              );
              maia.reply('d2d4');
              await tester.pumpAndSettle();
              saved = await ActiveSessionStore.load();
              expect(saved!['uciMoves'], ['e2e4', 'g8f6', 'd2d4', 'f6g4']);
              expect(maia.requests.length, 3);
              expect(find.byKey(const ValueKey('premove-queue')), findsNothing);
            }
            await disposeGame(tester);
          },
        );
      }
    }
  }

  for (final remaining in [99, 100, 101]) {
    for (final playerWhite in [false, true]) {
      testWidgets(
        '100ms penalty with $remaining ms, playerWhite=$playerWhite',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'premovePenalty': true,
            'multiplePremoves': true,
          });
          final maia = ControlledMaia();
          await ActiveSessionStore.save(
            gameRecord(
              pgn: playerWhite ? '1. e4 *' : null,
              playerWhite: playerWhite,
              white: playerWhite ? remaining : 5000,
              black: playerWhite ? 5000 : remaining,
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: GamePage(
                maiaEvaluator: maia.call,
                clockFactory: () => TestClock(250),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await queueMove(tester, playerWhite ? 'g1f3' : 'g8f6');
          maia.reply(playerWhite ? 'e7e5' : 'e2e4');
          await tester.pumpAndSettle();
          final saved = (await ActiveSessionStore.load())!;
          final moves = saved['uciMoves'] as List;
          final history = saved['clockHistory'] as List;
          if (remaining <= 100) {
            expect(moves.length, playerWhite ? 2 : 1);
            expect(saved[playerWhite ? 'whiteMillis' : 'blackMillis'], 0);
            expect(saved['forcedResult'], playerWhite ? '0-1' : '1-0');
            expect(maia.requests.length, 1);
          } else {
            expect(moves.last, playerWhite ? 'g1f3' : 'g8f6');
            expect((history.last as List)[playerWhite ? 0 : 1], 2001);
            expect(saved['forcedResult'], isNull);
          }
          expect(find.byKey(const ValueKey('premove-queue')), findsNothing);
          await disposeGame(tester);
        },
      );
    }
  }

  testWidgets(
    'invalid next premove cancels dependants without penalty or increment',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'premovePenalty': true,
        'multiplePremoves': true,
      });
      final maia = ControlledMaia();
      const fen = '4k3/8/8/8/8/3b4/P7/1N2K3 b - - 0 1';
      await ActiveSessionStore.save(
        gameRecord(pgn: AnalysisSession.fromFen(fen).pgn),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(17),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await queueMove(tester, 'b1c3');
      await queueMove(tester, 'c3d5');
      maia.reply('d3b1');
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expect(saved['uciMoves'], ['d3b1']);
      expect(saved['whiteMillis'], 4983);
      expect((saved['clockHistory'] as List).last, [5000, 6983]);
      expect(saved['forcedResult'], isNull);
      expect(find.byKey(const ValueKey('premove-queue')), findsNothing);
      expect(
        boardOf(tester).controller.fen,
        (chess.Chess.fromFEN(fen)..move('Bxb1')).fen,
      );
      await disposeGame(tester);
    },
  );

  testWidgets(
    'cancel restores actual position and single mode replaces the previous premove',
    (tester) async {
      for (final multiple in [true, false]) {
        SharedPreferences.setMockInitialValues({'multiplePremoves': multiple});
        final maia = ControlledMaia();
        await ActiveSessionStore.save(
          gameRecord(playerWhite: false, preset: 'unlimited'),
        );
        await tester.pumpWidget(
          MaterialApp(home: GamePage(maiaEvaluator: maia.call)),
        );
        await tester.pumpAndSettle();
        await queueMove(tester, 'g8f6');
        if (multiple) {
          await queueMove(tester, 'f6g4');
          await tester.tap(find.byKey(const ValueKey('cancel-premoves')));
          await tester.pumpAndSettle();
          expect(boardOf(tester).controller.fen, chess.Chess.DEFAULT_POSITION);
        } else {
          await queueMove(tester, 'b8c6');
        }
        maia.reply('e2e4');
        await tester.pumpAndSettle();
        expect(
          (await ActiveSessionStore.load())!['uciMoves'],
          multiple ? ['e2e4'] : ['e2e4', 'b8c6'],
        );
        await disposeGame(tester);
      }
    },
  );

  for (final completed in [false, true]) {
    testWidgets('tap and hold history controls, completed=$completed', (
      tester,
    ) async {
      final maia = ControlledMaia();
      final history = [
        [60000, 60000],
        [61900, 60000],
        [61900, 61700],
        [62800, 61700],
        [62800, 63000],
      ];
      final record = gameRecord(
        pgn: '1. e4 e5 2. Nf3 Nc6 ${completed ? '1-0' : '*'}',
        history: history,
        white: 61000,
        black: completed ? 0 : 63000,
        result: completed ? '1-0' : null,
      );
      await ActiveSessionStore.save(record);
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (completed) {
        Navigator.of(tester.element(find.byType(AlertDialog))).pop();
        await tester.pumpAndSettle();
      }
      final savedBefore = await ActiveSessionStore.load();
      final previous = find.byKey(const ValueKey('game-previous-move-button'));
      final next = find.byKey(const ValueKey('game-next-move-button'));
      String clock(String side) =>
          tester.widget<Text>(find.byKey(ValueKey('$side-clock'))).data!;
      if (completed) expect(clock('black'), '0:00.0');
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(
        boardOf(tester).controller.fen,
        AnalysisSession.fromPgn('1. e4 e5 2. Nf3 *').positions.last,
      );
      if (completed) {
        expect(clock('white'), '1:02');
        expect(clock('black'), '1:01');
      }
      await tester.longPress(previous);
      await tester.pumpAndSettle();
      expect(boardOf(tester).controller.fen, chess.Chess.DEFAULT_POSITION);
      expect(tester.widget<InkResponse>(previous).onTap, isNull);
      expect(tester.widget<InkResponse>(previous).onLongPress, isNull);
      if (completed) {
        expect(clock('white'), '1:00');
        expect(clock('black'), '1:00');
      }
      await tester.tap(next);
      await tester.pumpAndSettle();
      if (completed) {
        expect(clock('white'), '1:01');
        expect(clock('black'), '1:00');
      }
      await tester.longPress(next);
      await tester.pumpAndSettle();
      expect(
        boardOf(tester).controller.fen,
        AnalysisSession.fromPgn(record['pgn']! as String).positions.last,
      );
      expect(tester.widget<InkResponse>(next).onLongPress, isNull);
      if (completed) {
        expect(clock('white'), '1:01');
        expect(clock('black'), '0:00.0');
      }
      expect(await ActiveSessionStore.load(), savedBefore);
      expect(maia.requests, isEmpty);
      await disposeGame(tester);
    });
  }

  testWidgets(
    'legacy history displays unknown, and annotation metadata survives game restore',
    (tester) async {
      const pgn =
          '[TimeControl "600+7"]\n[Event "Keep"]\n[Result "1-0"]\n\n'
          '{Intro} 1. e4 \$1 {Original [%clk 0:09:59.123]} (1. d4 {Variation}) e5 1-0';
      await ActiveSessionStore.save(
        gameRecord(
          pgn: pgn,
          result: '1-0',
          history: [
            null,
            [599123, 600000],
          ],
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byKey(const ValueKey('game-previous-move-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('—'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('game-share-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy PGN'));
      await tester.pumpAndSettle();
      expect(copiedPgn, isNotNull);
      final parsed = dc.PgnGame.parsePgn(copiedPgn!);
      expect(parsed.headers['TimeControl'], '600+7');
      expect(parsed.comments, ['Intro']);
      expect(parsed.moves.children.first.data.nags, [1]);
      expect(copiedPgn, contains('Original [%clk 0:09:59.123]'));
      expect(copiedPgn, contains('Variation'));
      expect(RegExp(r'\[%clk ').allMatches(copiedPgn!).length, 1);
      await disposeGame(tester);
    },
  );
  testWidgets(
    'advanced premove preferences persist and disabled premoves stay disabled',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      SwitchListTile setting(String name) =>
          tester.widget<SwitchListTile>(find.byKey(ValueKey(name)));
      expect(setting('premoves-setting').value, true);
      expect(setting('premove-penalty-setting').value, false);
      expect(setting('multiple-premoves-setting').value, false);
      setting('premove-penalty-setting').onChanged!(true);
      setting('multiple-premoves-setting').onChanged!(true);
      await tester.pumpAndSettle();
      await disposeGame(tester);
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(setting('premove-penalty-setting').value, true);
      expect(setting('multiple-premoves-setting').value, true);
      setting('premoves-setting').onChanged!(false);
      await tester.pumpAndSettle();
      expect(setting('premove-penalty-setting').onChanged, isNull);
      await disposeGame(tester);
      final maia = ControlledMaia();
      await ActiveSessionStore.save(
        gameRecord(playerWhite: false, preset: 'unlimited'),
      );
      await tester.pumpWidget(
        MaterialApp(home: GamePage(maiaEvaluator: maia.call)),
      );
      await tester.pumpAndSettle();
      expect(boardOf(tester).settings.enablePremoves, false);
      await queueMove(tester, 'g8f6');
      maia.reply('e2e4');
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['uciMoves'], ['e2e4']);
      await disposeGame(tester);
    },
  );

  for (final ending in [
    ('checkmate', '1. f3 e5 2. g4 Qh4# 0-1', null),
    (
      'stalemate',
      '[FEN "7k/5Q2/6K1/8/8/8/8/8 b - - 0 1"]\n[SetUp "1"]\n1/2-1/2',
      null,
    ),
    ('resignation', '1. e4 e5 0-1', '0-1'),
    ('agreed draw', '1. e4 e5 1/2-1/2', '1/2-1/2'),
    ('timeout', '1. e4 e5 1-0', '1-0'),
  ]) {
    testWidgets(
      'new-game confirmation preserves completed ${ending.$1} on cancel',
      (tester) async {
        await ActiveSessionStore.save(
          gameRecord(pgn: ending.$2, result: ending.$3),
        );
        await tester.pumpWidget(const MaterialApp(home: GamePage()));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(AlertDialog))).pop();
        await tester.pumpAndSettle();
        final before = await ActiveSessionStore.load();
        expect(find.byTooltip('New game'), findsOneWidget);
        expect(find.byTooltip('Reset game'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('new-game-button')));
        await tester.pumpAndSettle();
        expect(find.text('Start a new game?'), findsOneWidget);
        expect(
          find.text('Your completed game will remain in Recent Games.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(await ActiveSessionStore.load(), before);
        await tester.tap(find.byKey(const ValueKey('new-game-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start new game'));
        await tester.pumpAndSettle();
        expect((await ActiveSessionStore.load())!['uciMoves'], isEmpty);
        expect(find.byTooltip('Reset game'), findsOneWidget);
        await disposeGame(tester);
      },
    );
  }

  for (final action in ['cancel', 'takeback', 'reset', 'restart', 'history']) {
    testWidgets('$action clears queued premoves and rejects a late old reply', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'multiplePremoves': true,
        'premovePenalty': true,
      });
      final maia = ControlledMaia();
      await ActiveSessionStore.save(
        gameRecord(
          pgn: '1. e4 *',
          history: [
            [60000, 60000],
            [59876, 60000],
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await queueMove(tester, 'g1f3');
      await queueMove(tester, 'f3g5');
      if (action == 'cancel') {
        await tester.tap(find.byKey(const ValueKey('cancel-premoves')));
      } else if (action == 'history') {
        await tester.longPress(
          find.byKey(const ValueKey('game-previous-move-button')),
        );
      } else if (action == 'restart') {
        await disposeGame(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              maiaEvaluator: maia.call,
              clockFactory: () => TestClock(0),
            ),
          ),
        );
      } else if (action == 'takeback') {
        await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Take back move'));
      } else {
        await tester.tap(find.byKey(const ValueKey('new-game-button')));
        await tester.pumpAndSettle();
        expect(
          find.text('This game will be permanently erased.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('premove-queue')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('new-game-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('premove-queue')), findsNothing);
      if (action == 'restart') {
        // Complete the request belonging to the removed widget, then the new one.
        final policy = Float32List(4352)..fillRange(0, 4352, -100);
        policy[MaiaEncoding.moveIndex('e7e5', true)] = 100;
        maia.requests.first.$2.complete(policy);
        await tester.pumpAndSettle();
      }
      maia.reply('e7e5');
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expect(
        saved['uciMoves'],
        ['cancel', 'restart', 'history'].contains(action)
            ? ['e2e4', 'e7e5']
            : [],
      );
      if (action == 'takeback') {
        expect(
          AnalysisSession.fromPgn(saved['pgn'] as String).uciMoves,
          isEmpty,
        );
        expect(saved['variations'], isNotEmpty);
        // This checkpoint must restore the actual starting position, not the unplayed line.
        await disposeGame(tester);
        await tester.pumpWidget(
          MaterialApp(home: GamePage(maiaEvaluator: maia.call)),
        );
        await tester.pumpAndSettle();
        expect(boardOf(tester).controller.fen, chess.Chess.DEFAULT_POSITION);
      }
      await disposeGame(tester);
    });
  }

  for (final scenario in [
    ('castling', '4k3/p7/8/8/8/8/P7/4K2R b K - 0 1', 'a7a6', 'e1g1'),
    ('promotion', '4k3/P6p/8/8/8/8/8/4K3 b - - 0 1', 'h7h6', 'a7a8q'),
    ('underpromotion', '4k3/P6p/8/8/8/8/8/4K3 b - - 0 1', 'h7h6', 'a7a8n'),
    ('recapture', '4k3/8/8/8/8/3B4/4Pr2/4K3 b - - 0 1', 'f2e2', 'd3e2'),
    ('en passant', '4k3/3p4/8/4P3/8/8/8/4K3 b - - 0 1', 'd7d5', 'e5d6'),
  ]) {
    testWidgets(
      'queued ${scenario.$1} is validated and committed with one charge',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'multiplePremoves': true,
          'premovePenalty': true,
        });
        final maia = ControlledMaia();
        await ActiveSessionStore.save(
          gameRecord(pgn: AnalysisSession.fromFen(scenario.$2).pgn),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              maiaEvaluator: maia.call,
              clockFactory: () => TestClock(17),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (scenario.$1 == 'underpromotion') {
          boardOf(tester).controller.premove = dc.NormalMove.fromUci(
            scenario.$4,
          );
          await flush(tester);
        } else {
          await queueMove(tester, scenario.$4);
        }
        maia.reply(scenario.$3);
        await tester.pumpAndSettle();
        final saved = (await ActiveSessionStore.load())!;
        expect(saved['uciMoves'], [scenario.$3, scenario.$4]);
        expect((saved['clockHistory'] as List).last, [6900, 6983]);
        await disposeGame(tester);
      },
    );
  }
  for (final draw in [false, true]) {
    testWidgets(
      'final clocks freeze at ${draw ? 'draw agreement' : 'resignation'}',
      (tester) async {
        final clock = TestClock(0);
        const fen = '4k3/pp6/8/8/8/8/PP6/4K3 w - - 0 1';
        await ActiveSessionStore.save(
          gameRecord(
            pgn: AnalysisSession.fromFen(fen).pgn,
            history: [
              [5000, 5000],
            ],
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              clockFactory: () => clock,
              drawEvaluator: (_) async => const StockfishReview(0, 'a2a3'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        clock.milliseconds = 1234;
        if (draw) {
          await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Offer draw'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Offer draw'));
        } else {
          await tester.tap(find.byKey(const ValueKey('quick-resign-button')));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Resign'));
        }
        await tester.pumpAndSettle();
        final saved = (await ActiveSessionStore.load())!;
        expect(saved['whiteMillis'], 3766);
        expect(saved['blackMillis'], 5000);
        expect(saved['clockHistory'], [
          [5000, 5000],
        ]);
        clock.milliseconds = 4999;
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('white-clock'))).data,
          '0:03.7',
        );
        await disposeGame(tester);
      },
    );
  }

  testWidgets(
    'timed takeback replaces mainline clocks and retains existing branch notes',
    (tester) async {
      final maia = ControlledMaia();
      const pgn = '1. e4 e5 2. Nf3 {Keep knight note} Nc6 *';
      await ActiveSessionStore.save(
        gameRecord(
          pgn: pgn,
          history: [
            [60000, 60000],
            [61001, 60000],
            [61001, 61002],
            [62003, 61002],
            [62003, 62004],
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(17),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take back move'));
      await tester.pumpAndSettle();
      boardOf(tester).onMove!(dc.NormalMove.fromUci('f1c4'));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      final parsed = dc.PgnGame.parsePgn(saved['pgn'] as String);
      final moves = parsed.moves.mainline().toList();
      expect(moves.map((move) => move.san), ['e4', 'e5', 'Bc4']);
      expect(moves.last.comments, ['[%clk 0:01:02.984]']);
      expect(saved['pgn'], contains('Keep knight note'));
      final branches = PgnVariationExporter.parseTree(saved['pgn'] as String)
          .single
          .children;
      expect(branches.single.sanMoves, ['Nf3', 'Nc6']);
      expect(
        branches.single.annotations.any(
          (note) => note.toString().contains('[%clk'),
        ),
        false,
      );
      expect((saved['clockHistory'] as List).length, 4);
      await disposeGame(tester);
    },
  );

  testWidgets(
    'restored timed takeback removes clock tags from the abandoned branch',
    (tester) async {
      const pgn =
          '[TimeControl "60+2"]\n\n'
          '1. e4 {[%clk 0:01:01.001]} e5 {[%clk 0:01:01.002]} '
          '2. Nf3 \$1 {Keep knight note [%clk 0:01:02.003]} '
          'Nc6 {[%clk 0:01:02.004]} *';
      await ActiveSessionStore.save(
        gameRecord(
          pgn: pgn,
          history: [
            [60000, 60000],
            [61001, 60000],
            [61001, 61002],
            [62003, 61002],
            [62003, 62004],
          ],
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take back move'));
      await tester.pumpAndSettle();

      final saved = (await ActiveSessionStore.load())!;
      final exported = saved['pgn'] as String;
      expect(RegExp(r'\[%clk ').allMatches(exported).length, 2);
      expect(AnalysisSession.fromPgn(exported).uciMoves, ['e2e4', 'e7e5']);
      expect(exported, contains('Unplayed takeback line after ply 2'));
      expect(exported, contains('Keep knight note'));
      expect(exported, contains(r'$1'));
      final branch = (saved['variations'] as List)
          .map(
            (item) => RecordedVariation.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .singleWhere((line) => line.basePly == 2);
      expect(branch.sanMoves, ['Nf3', 'Nc6']);
      expect(branch.annotations.first['nags'], [1]);
      expect(branch.annotations.first['comments'], ['Keep knight note']);
      expect(branch.annotations.toString(), isNot(contains('[%clk')));
      await disposeGame(tester);
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      expect(
        boardOf(tester).controller.fen,
        AnalysisSession.fromPgn('1. e4 e5 *').positions.last,
      );
      final maia = ControlledMaia();
      await disposeGame(tester);
      await tester.pumpWidget(
        MaterialApp(home: GamePage(maiaEvaluator: maia.call)),
      );
      await tester.pumpAndSettle();
      boardOf(tester).onMove!(dc.NormalMove.fromUci('f1c4'));
      await tester.pumpAndSettle();
      final continued = (await ActiveSessionStore.load())!['pgn'] as String;
      expect(continued, isNot(contains('Unplayed takeback line')));
      expect(
        PgnVariationExporter.parseTree(continued)
            .single
            .children
            .single
            .sanMoves,
        ['Nf3', 'Nc6'],
      );
      await disposeGame(tester);
    },
  );

  testWidgets(
    'mating premove clears later moves without requesting another reply',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'multiplePremoves': true,
        'premovePenalty': true,
      });
      final maia = ControlledMaia();
      const fen = '8/8/8/8/8/6k1/P3r3/4R1K1 w - - 0 1';
      await ActiveSessionStore.save(
        gameRecord(pgn: AnalysisSession.fromFen(fen).pgn, playerWhite: false),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(17),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await queueMove(tester, 'e2e1');
      await queueMove(tester, 'e1e2');
      maia.reply('a2a3');
      await tester.pumpAndSettle();
      expect(find.text('Black is victorious'), findsOneWidget);
      expect((await ActiveSessionStore.load())!['uciMoves'], ['a2a3', 'e2e1']);
      expect(find.byKey(const ValueKey('premove-queue')), findsNothing);
      expect(maia.requests.length, 1);
      await disposeGame(tester);
    },
  );

  for (final remaining in [99, 100, 101]) {
    testWidgets('premove penalty without increment, $remaining ms remains', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'premovePenalty': true});
      final maia = ControlledMaia();
      await ActiveSessionStore.save(
        gameRecord(playerWhite: false, preset: 'bullet', black: remaining),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(17),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await queueMove(tester, 'g8f6');
      maia.reply('e2e4');
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expect(saved['blackMillis'], remaining <= 100 ? 0 : 1);
      expect(saved['uciMoves'], remaining <= 100 ? ['e2e4'] : ['e2e4', 'g8f6']);
      await disposeGame(tester);
    });
  }

  testWidgets('single premove accepts the king-to-rook castling gesture', (
    tester,
  ) async {
    final maia = ControlledMaia();
    const fen = '4k3/p7/8/8/8/8/P7/4K2R b K - 0 1';
    await ActiveSessionStore.save(
      gameRecord(pgn: AnalysisSession.fromFen(fen).pgn, preset: 'unlimited'),
    );
    await tester.pumpWidget(
      MaterialApp(home: GamePage(maiaEvaluator: maia.call)),
    );
    await tester.pumpAndSettle();
    await queueMove(tester, 'e1h1');
    maia.reply('a7a6');
    await tester.pumpAndSettle();
    expect((await ActiveSessionStore.load())!['uciMoves'], ['a7a6', 'e1g1']);
    await disposeGame(tester);
  });
  testWidgets(
    'completed history never starts the clock and Chessnut never queues premoves',
    (tester) async {
      var clocks = 0;
      await ActiveSessionStore.save(
        gameRecord(pgn: '1. e4 e5 1-0', result: '1-0'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            clockFactory: () {
              clocks++;
              return TestClock(0);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byKey(const ValueKey('game-previous-move-button')),
      );
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byKey(const ValueKey('game-next-move-button')),
      );
      await tester.pumpAndSettle();
      expect(clocks, 0);
      await disposeGame(tester);
      SharedPreferences.setMockInitialValues({
        'multiplePremoves': true,
        'premovePenalty': true,
      });
      final transport = SimulatedElectronicBoard();
      await ActiveSessionStore.save({
        ...gameRecord(pgn: '1. e4 *', preset: 'unlimited'),
        'electronicBoard': 'chessnut-go',
      });
      await tester.pumpWidget(
        MaterialApp(home: GamePage(electronicBoardTransport: transport)),
      );
      await tester.pumpAndSettle();
      expect(boardOf(tester).controller.interactive, false);
      boardOf(tester).controller.premove = dc.NormalMove.fromUci('g1f3');
      await flush(tester);
      expect(find.byKey(const ValueKey('premove-queue')), findsNothing);
      expect(boardOf(tester).controller.premove, isNull);
      await disposeGame(tester);
      await transport.close();
    },
  );
  testWidgets(
    'dragging a projected piece appends a premove without resizing the board',
    (tester) async {
      SharedPreferences.setMockInitialValues({'multiplePremoves': true});
      final maia = ControlledMaia();
      await ActiveSessionStore.save(
        gameRecord(playerWhite: false, preset: 'unlimited'),
      );
      await tester.pumpWidget(
        MaterialApp(home: GamePage(maiaEvaluator: maia.call)),
      );
      await tester.pumpAndSettle();
      final boardSize = tester.getSize(
        find.byKey(const ValueKey('game-board')),
      );
      for (final (from, to) in [('g8', 'f6'), ('f6', 'g4')]) {
        final origin = squareCenter(tester, from);
        await tester.dragFrom(origin, squareCenter(tester, to) - origin);
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('game-board'))),
          boardSize,
        );
      }
      expect(find.textContaining('1. g8–f6  2. f6–g4'), findsOneWidget);
      maia.reply('e2e4');
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['uciMoves'], ['e2e4', 'g8f6']);
      expect(find.textContaining('1. f6–g4'), findsOneWidget);
      await disposeGame(tester);
    },
  );
  testWidgets(
    'legacy takeback without snapshots preserves both current clocks',
    (tester) async {
      final maia = ControlledMaia();
      await ActiveSessionStore.save(
        gameRecord(pgn: '1. e4 *', white: 7000, black: 9000),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(17),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take back move'));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      // White has started a new turn; Black retains the time used before undo.
      expect(saved['whiteMillis'], 6983);
      expect(saved['blackMillis'], 8983);
      expect(saved['clockHistory'], [null]);
      expect(saved['pgn'], isNot(contains('[%clk')));
      await disposeGame(tester);
    },
  );
}
