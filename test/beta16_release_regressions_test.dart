import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'legacy game variation survives equivalent en-passant FEN notation',
    (tester) async {
      final session = AnalysisSession.fromPgn('1. e4 e5 1-0');
      final legacyFen = dc.Chess.fromSetup(
        dc.Setup.parseFen(session.positions[1]),
      ).fen;
      expect(legacyFen, isNot(session.positions[1]));
      await ActiveSessionStore.save({
        ...gameRecord(pgn: session.pgn, result: '1-0'),
        'variations': [
          RecordedVariation(
            basePly: 1,
            baseFen: legacyFen,
            sanMoves: const ['c5', 'Nf3'],
            annotations: const [
              {
                'comments': ['Keep Sicilian note'],
              },
            ],
          ).toJson(),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      final pgn = saved['pgn'] as String;
      expect(pgn, contains('Keep Sicilian note'));
      final root = PgnVariationExporter.parseTree(pgn).single;
      expect(root.sanMoves, ['e4', 'e5']);
      expect(root.children.single.sanMoves, ['c5', 'Nf3']);
      await disposeGame(tester);
    },
  );

  testWidgets(
    'takeback nests a legacy continuation under its abandoned parent',
    (tester) async {
      final session = AnalysisSession.fromPgn('1. e4 e5 2. d4 d5 *');
      await ActiveSessionStore.save({
        ...gameRecord(pgn: session.pgn),
        'variations': [
          RecordedVariation(
            basePly: 3,
            baseFen: dc.Chess.fromSetup(dc.Setup.parseFen(session.positions[3]))
                .fen,
            sanMoves: const ['c5'],
            annotations: const [
              {
                'comments': ['Keep counterattack'],
              },
            ],
          ).toJson(),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take back move'));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      final lines = (saved['variations'] as List)
          .map(
            (value) => RecordedVariation.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList();
      expect(lines, hasLength(1));
      expect(lines.single.sanMoves, ['d4', 'd5']);
      expect(lines.single.children.single.sanMoves, ['c5']);
      expect(saved['pgn'], contains('Keep counterattack'));
      expect(AnalysisSession.fromPgn(saved['pgn'] as String).uciMoves, [
        'e2e4',
        'e7e5',
      ]);
      await disposeGame(tester);
    },
  );

  test(
    'variation matching preserves a legally available en-passant distinction',
    () {
      final session = AnalysisSession.fromPgn('1. e4 a6 2. e5 d5 3. Nf3 *');
      final fen = session.positions[4];
      expect(
        dc.Chess.fromSetup(dc.Setup.parseFen(fen)).fen.split(' ')[3],
        'd6',
      );
      final withoutCapture = fen.replaceFirst(' d6 ', ' - ');
      final exported = PgnVariationExporter.export(
        session.pgn,
        session.sanMoves,
        [
          RecordedVariation(
            basePly: 4,
            baseFen: withoutCapture,
            sanMoves: const ['Nc3'],
            annotations: const [
              {
                'comments': ['Different legal position'],
              },
            ],
          ),
        ],
        mainPositions: session.positions,
        preserveEmptyMainline: true,
      );
      expect(exported, isNot(contains('Different legal position')));
    },
  );

  test(
    'invalid orphan variation positions do not break a valid game export',
    () {
      final session = AnalysisSession.fromPgn('1. e4 e5 *');
      for (final invalid in ['invalid', '8/8/8/8/8/8/8/8 b - - 0 1']) {
        final exported = PgnVariationExporter.export(
          session.pgn,
          session.sanMoves,
          [
            RecordedVariation(
              basePly: 1,
              baseFen: invalid,
              sanMoves: const ['c5'],
            ),
          ],
          mainPositions: session.positions,
        );
        expect(AnalysisSession.fromPgn(exported).uciMoves, session.uciMoves);
        expect(exported, isNot(contains('c5')));
      }
    },
  );

  for (final seed in [20260910, 20260911, 20260912]) {
    testWidgets(
      'release trace $seed: moves, repeated takebacks, stale replies and reopen',
      (tester) async {
        final random = Random(seed);
        final expected = chess.Chess();
        final uci = <String>[];
        final clocks = <List<int>>[
          [300000, 300000],
        ];
        var maia = ControlledMaia();
        await ActiveSessionStore.save(
          gameRecord(
            pgn: '[Event "Release trace $seed"]\n\n{Keep opening note} *',
            white: 300000,
            black: 300000,
            history: clocks,
          ),
        );

        Future<void> open() async {
          await tester.pumpWidget(
            MaterialApp(
              home: GamePage(
                maiaEvaluator: maia.call,
                clockFactory: () => TestClock(0),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        String chooseMove() {
          final legal = expected.moves({'asObjects': true}).cast<chess.Move>();
          return MaiaEncoding.uci(legal[random.nextInt(legal.length)]);
        }

        void recordMove(String move) {
          final color = expected.turn == chess.Color.WHITE ? 0 : 1;
          expect(
            expected.move({
              'from': move.substring(0, 2),
              'to': move.substring(2, 4),
              if (move.length == 5) 'promotion': move[4],
            }),
            isTrue,
          );
          uci.add(move);
          final snapshot = List<int>.of(clocks.last);
          snapshot[color] += 2000;
          clocks.add(snapshot);
        }

        Future<void> verify() async {
          final saved = (await ActiveSessionStore.load())!;
          final pgn = saved['pgn'] as String;
          expect(saved['uciMoves'], uci);
          expect(AnalysisSession.fromPgn(pgn).uciMoves, uci);
          expect(saved['clockHistory'], clocks);
          expect(pgn, contains('Keep opening note'));
          expect(
            dc.PgnGame.parsePgn(pgn).headers['Event'],
            'Release trace $seed',
          );
          expect(dc.PgnGame.parsePgn(pgn).moves.mainline().length, uci.length);
          expect(RegExp(r'\[%clk ').allMatches(pgn).length, uci.length);
          expect(
            dc.Chess.fromSetup(
              dc.Setup.parseFen(boardOf(tester).controller.fen),
            ).fen,
            dc.Chess.fromSetup(dc.Setup.parseFen(expected.fen)).fen,
          );
          // Validate all exported branches, not only the played main line.
          PgnVariationExporter.parseTree(pgn);
          final leaves = <String>{};
          void visit(dc.PgnNode<dc.PgnNodeData> node, List<String> path) {
            if (node.children.isEmpty) {
              expect(
                leaves.add(path.join(' ')),
                isTrue,
                reason: 'Duplicate continuation in release trace $seed: $path',
              );
            }
            for (final child in node.children) {
              visit(child, [...path, child.data.san]);
            }
          }

          visit(dc.PgnGame.parsePgn(pgn).moves, []);
          expect(tester.takeException(), isNull);
        }

        Future<void> takeBack(int count) async {
          await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Take back move'));
          await tester.pumpAndSettle();
          for (var i = 0; i < count; i++) {
            expected.undo();
            uci.removeLast();
            clocks.removeLast();
          }
        }

        await open();
        for (var turn = 0; turn < 40 && !expected.game_over; turn++) {
          final human = chooseMove();
          boardOf(tester).onMove!(dc.NormalMove.fromUci(human));
          recordMove(human);
          await tester.pumpAndSettle();
          if (expected.game_over) break;
          final reply = chooseMove();
          if (turn % 7 == 2) {
            // Undo while inference is pending, then deliver the old result.
            await takeBack(1);
            maia.reply(reply);
            await tester.pumpAndSettle();
          } else {
            maia.reply(reply);
            recordMove(reply);
            await tester.pumpAndSettle();
            if (expected.game_over) break;
            if (turn % 3 == 0) await takeBack(2);
          }
          await verify();
          if (turn % 4 == 0) {
            final before = (await ActiveSessionStore.load())!['pgn'];
            await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Analysis Board'));
            await tester.pumpAndSettle();
            Navigator.of(tester.element(find.byType(ReviewPage))).pop();
            await tester.pumpAndSettle();
            expect(
              (await ActiveSessionStore.load())!['pgn'],
              before,
              reason:
                  'Review visit must preserve the complete PGN at turn $turn',
            );
            await verify();
          }
          if (turn % 5 == 0) {
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            await tester.pumpAndSettle();
            await disposeGame(tester);
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            maia = ControlledMaia();
            await open();
            // Loading must not append a clock snapshot or replay a takeback.
            await verify();
          }
        }
        await disposeGame(tester);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
