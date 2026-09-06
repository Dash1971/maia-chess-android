// Audit regressions: these assert intended behavior and expose current defects.
import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('audit: PGN import retains variations and comments', () {
    final imported = AnalysisSession.fromPgn(
      '[Result "*"]\n\n1. e4 {Keep this note} (1. d4 d5) e5 *',
    );
    expect(imported.pgn, contains('d4'));
    expect(imported.pgn, contains('Keep this note'));
  });

  test('audit: root PGN siblings attach to the initial position', () {
    final exported = PgnVariationExporter.export(
      '[Result "*"]\n\n*',
      const [],
      const [
        RecordedVariation(
          basePly: 0,
          baseFen: chess.Chess.DEFAULT_POSITION,
          sanMoves: ['e4', 'e5'],
        ),
        RecordedVariation(
          basePly: 0,
          baseFen: chess.Chess.DEFAULT_POSITION,
          sanMoves: ['d4', 'd5'],
        ),
      ],
    );
    final parsed = dc.PgnGame.parsePgn(exported);
    expect(parsed.moves.children, hasLength(2), reason: exported);
  });

  test('audit: custom black-to-move FEN preserves PGN move numbering', () {
    const fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 17';
    final session = AnalysisSession.fromFen(fen);
    final exported = PgnVariationExporter.export(session.pgn, const [], const [
      RecordedVariation(basePly: 0, baseFen: fen, sanMoves: ['e5']),
    ]);
    expect(exported, contains('17... e5'));
  });

  test('audit: a FEN analysis retains its setup headers on export', () {
    const fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 17';
    final session = AnalysisSession.fromFen(fen);
    final exported = PgnVariationExporter.export(session.pgn, const [], const [
      RecordedVariation(basePly: 0, baseFen: fen, sanMoves: ['e5']),
    ]);
    expect(exported, contains('[FEN "$fen"]'));
  });

  test('audit: classify the first Black move from its actual side', () {
    const fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 17';
    final game = chess.Chess.fromFEN(fen)..move('e5');
    final result = MoveClassifier.classify(
      scores: const [StockfishReview(0, 'e7e5'), StockfishReview(500, 'e2e4')],
      positions: [fen, game.fen],
      uciMoves: ['e7e5'],
    );
    expect(result, hasLength(1));
    expect(result.single.classification, MoveClassification.blunder);
    expect(result.single.whiteMoved, isFalse);
  });

  test('audit: empty editor FEN is rejected before opening the board', () {
    expect(
      () => AnalysisSession.fromFen('8/8/8/8/8/8/8/8 w - - 0 1'),
      throwsFormatException,
    );
  });

  testWidgets('audit: first-move takeback does not replace the actual game', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn('[Result "*"]\n\n1. d4 d5 *');
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: session.positions,
          uciMoves: session.uciMoves,
          sanMoves: session.sanMoves,
          pgn: session.pgn,
          playerIsWhite: true,
          initialVariations: const [
            RecordedVariation(
              basePly: 0,
              baseFen: chess.Chess.DEFAULT_POSITION,
              sanMoves: ['e4', 'e5'],
            ),
          ],
          onHome: () {},
          onSessionChanged: (_, _, _) async {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('d4'), findsOneWidget);
    expect(find.text('d5'), findsOneWidget);
  });

  testWidgets(
    'audit: replaying a saved first move preserves its continuation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: const [chess.Chess.DEFAULT_POSITION],
            uciMoves: const [],
            sanMoves: const [],
            pgn: '[Result "*"]\n\n*',
            playerIsWhite: true,
            onHome: () {},
            onSessionChanged: (_, _, _) async {},
            evaluator: (_) async => const StockfishReview(0, 'e2e4'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final uci in ['e2e4', 'e7e5', 'g1f3']) {
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
          dc.NormalMove.fromUci(uci),
        );
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Previous move'));
        await tester.pumpAndSettle();
      }
      tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
        dc.NormalMove.fromUci('e2e4'),
      );
      await tester.pumpAndSettle();
      expect(find.text('e5'), findsOneWidget);
      expect(find.text('Nf3'), findsOneWidget);
    },
  );

  testWidgets(
    'audit: a failed Maia opening move displays a recoverable error',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            startingFen: chess.Chess.DEFAULT_POSITION,
            startingSide: PlayerSide.black,
            maiaEvaluator: (_, _) async =>
                throw StateError('simulated inference failure'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Maia error'), findsOneWidget);
    },
  );

  testWidgets('audit: analysis layout fits a landscape phone', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [chess.Chess.DEFAULT_POSITION],
          uciMoves: const [],
          sanMoves: const [],
          pgn: '*',
          playerIsWhite: true,
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('audit: full analysis stops scheduling work while backgrounded', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaiaChessApp());
    await tester.pumpAndSettle();
    final session = AnalysisSession.fromPgn('[Result "*"]\n\n1. e4 e5 *');
    final gate = Completer<StockfishReview>();
    final evaluated = <String>[];
    unawaited(
      Navigator.of(tester.element(find.byType(GamePage))).push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewPage(
            positions: session.positions,
            uciMoves: session.uciMoves,
            sanMoves: session.sanMoves,
            pgn: session.pgn,
            playerIsWhite: true,
            onHome: () {},
            evaluator: (fen) {
              evaluated.add(fen);
              if (evaluated.length == 2) return gate.future;
              return Future.value(const StockfishReview(0, 'e2e4'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('graph-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    await tester.pump();
    expect(evaluated, hasLength(2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    gate.complete(const StockfishReview(0, 'e7e5'));
    await tester.pump();
    await tester.pump();
    final countWhilePaused = evaluated.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(countWhilePaused, 2);
  });
}
