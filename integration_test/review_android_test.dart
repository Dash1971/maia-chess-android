import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';

import '../test/fixtures/variation_navigation_game.dart';
import '../test/fixtures/electronic_board.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(
    () => maiaEngineChannel.invokeMethod<void>('setKeepScreenOn', {
      'enabled': true,
    }),
  );
  tearDownAll(
    () => maiaEngineChannel.invokeMethod<void>('setKeepScreenOn', {
      'enabled': false,
    }),
  );

  testWidgets('real Maia bridge returns a typed policy vector', (tester) async {
    final response = await MaiaInferenceQueue.predict({
      'tokens': MaiaEncoding.historicalTokens([chess.Chess.DEFAULT_POSITION]),
      'selfElo': 1500,
      'opponentElo': 1500,
    }, timeout: const Duration(minutes: 3));

    expect(response, isA<Float32List>());
    expect(response, hasLength(4352));
    expect(response!.every((value) => value.isFinite), isTrue);
  });

  Future<void> waitForRealEvaluation(WidgetTester tester) async {
    for (var i = 0; i < 240; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final panel = find.byKey(const ValueKey('analysis-engine-lines'));
      final analyzing = find.descendant(
        of: panel,
        matching: find.text('Analyzing…'),
      );
      if (panel.evaluate().isNotEmpty && analyzing.evaluate().isEmpty) {
        expect(find.textContaining('Stockfish failed:'), findsNothing);
        return;
      }
    }
    fail('real Stockfish evaluation did not finish within 24 seconds');
  }

  testWidgets('move 16 returns to the main line with real engines on Android', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn(variationNavigationPgn);
    final root = PgnVariationExporter.parseTree(session.pgn).single;
    final branch = root.children.singleWhere((v) => v.basePly == 30);
    final position = chess.Chess.fromFEN(branch.baseFen);
    for (final san in branch.sanMoves) {
      expect(position.move(san), isTrue);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisBoardPage(
          initialSession: session,
          initialCurrentFen: position.fen,
          maiaElo: 1600,
        ),
      ),
    );
    await tester.pump();
    await waitForRealEvaluation(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('previous-move-button')));
      await tester.pump();
    }
    await waitForRealEvaluation(tester);
    final selected = find.byKey(const ValueKey('mainline-move-29'));
    expect(tester.widget<Material>(selected).color, isNot(Colors.transparent));
    final board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    expect(
      board.controller.fen,
      dc.Chess.fromSetup(dc.Setup.parseFen(session.positions[30])).fen,
    );
    expect(board.controller.lastMove?.uci, session.uciMoves[29]);
    await tester.tap(find.byKey(const ValueKey('next-move-button')));
    await tester.pump();
    await waitForRealEvaluation(tester);
    expect(
      tester
          .widget<Material>(find.byKey(const ValueKey('mainline-move-30')))
          .color,
      isNot(Colors.transparent),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('pasted PGN crosses the isolate boundary on Android', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisBoardPage(
          initialSession: AnalysisSession.start(),
          maiaElo: 1600,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analysis-actions-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load PGN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), variationNavigationPgn);
    await tester.tap(find.widgetWithText(FilledButton, 'Load'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      final review = tester.widget<ReviewPage>(find.byType(ReviewPage));
      if (review.sanMoves.lastOrNull == 'Ra4#') break;
    }
    expect(
      tester.widget<ReviewPage>(find.byType(ReviewPage)).sanMoves.last,
      'Ra4#',
    );
    expect(find.text('Qc3'), findsOneWidget);
    await waitForRealEvaluation(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('real Stockfish survives navigation and graph taps on Android', (
    tester,
  ) async {
    const positions = [
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'rnbqkbnr/pppppppp/8/8/8/5P2/PPPPP1PP/RNBQKBNR b KQkq - 0 1',
      'rnbqkbnr/pppp1ppp/8/4p3/8/5P2/PPPPP1PP/RNBQKBNR w KQkq - 0 2',
      'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
      'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: positions,
          uciMoves: const ['f2f3', 'e7e5', 'g2g4', 'd8h4'],
          sanMoves: const ['f3', 'e5', 'g4', 'Qh4#'],
          playerIsWhite: true,
          pgn: '1. f3 e5 2. g4 Qh4#',
          onHome: () {},
          maiaEvaluator: (_, _) async => null,
        ),
      ),
    );

    await waitForRealEvaluation(tester);
    for (var ply = 1; ply < positions.length; ply++) {
      await tester.tap(find.byKey(const ValueKey('next-move-button')));
      await tester.pump();
      await waitForRealEvaluation(tester);
      expect(tester.takeException(), isNull, reason: 'real engine ply $ply');
    }

    // Recreate the page so graph analysis cannot reuse the evaluations above.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: positions,
          uciMoves: const ['f2f3', 'e7e5', 'g2g4', 'd8h4'],
          sanMoves: const ['f3', 'e5', 'g4', 'Qh4#'],
          playerIsWhite: true,
          pgn: '1. f3 e5 2. g4 Qh4#',
          onHome: () {},
          maiaEvaluator: (_, _) async => null,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('graph-tab')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    for (var i = 0; i < 600; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(AnalysisGraph).evaluate().isNotEmpty) break;
    }
    expect(find.textContaining('Stockfish failed:'), findsNothing);
    expect(find.byType(AnalysisGraph), findsOneWidget);
    for (final alignment in const [-0.9, 0.0, 0.9]) {
      // The plot can extend below the clipped panel on compact screens.
      // Scroll it into view so the tap cannot hit the toolbar underneath it.
      final plot = find.descendant(
        of: find.byType(AnalysisGraph),
        matching: find.byType(GestureDetector),
      );
      await Scrollable.ensureVisible(tester.element(plot), alignment: 0.5);
      await tester.pump();
      final rect = tester.getRect(plot);
      await tester.tapAt(
        Offset(rect.center.dx + alignment * rect.width / 2, rect.center.dy),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<AnalysisGraph>(find.byType(AnalysisGraph)).selectedPly,
        ((alignment + 1) / 2 * (positions.length - 1)).round(),
      );
    }
  });

  testWidgets('reported game review survives every Next move on Android', (
    tester,
  ) async {
    const pgn = '''
[Result "1/2-1/2"]

1. b4 e5 2. Bb2 Nc6 3. b5 Nd4 4. e3 Nxb5 5. Bxb5 c6 6. Be2 d6
7. Nf3 Nf6 8. c4 Be7 9. Nc3 O-O 10. O-O h6 11. a4 Nh7 12. d4 exd4
13. exd4 f5 14. d5 c5 15. Re1 f4 16. Bd3 Ng5 17. Nxg5 Bxg5 18. Ne4 f3
19. Nxg5 Qxg5 20. g3 Qh5 21. h4 Qg4 22. Be4 Bf5 23. Bxf3 Qh3
24. Qe2 Rae8 25. Qf1 Rxe1 26. Rxe1 Qxf1+ 27. Kxf1 Bd3+ 28. Be2 Bc2
29. a5 b6 30. axb6 axb6 31. Rc1 Be4 32. Ke1 Re8 33. Kd2 Bf5
34. Re1 Rf8 35. Bd3 Bg4 36. Re7 Rxf2+ 37. Kc3 Rf3 38. Rb7 Bf5
39. Rxb6 Rxd3+ 40. Kc2 Rxg3+ 41. Kc1 Rg1+ 42. Kd2 Rg2+
43. Kc1 Rg1+ 44. Kd2 Rg2+ 45. Kc1 Rg1+ 1/2-1/2
''';
    final loaded = chess.Chess()..load_pgn(pgn);
    final history = loaded.getHistory({
      'verbose': true,
    }).cast<Map<String, dynamic>>();
    final replay = chess.Chess();
    final positions = <String>[replay.fen];
    final uciMoves = <String>[];
    final sanMoves = <String>[];
    for (final move in history) {
      final from = move['from'] as String;
      final to = move['to'] as String;
      final promotion = move['promotion'] as String?;
      expect(
        replay.move({'from': from, 'to': to, 'promotion': ?promotion}),
        isTrue,
      );
      uciMoves.add('$from$to${promotion ?? ''}');
      sanMoves.add(move['san'] as String);
      positions.add(replay.fen);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: positions,
          uciMoves: uciMoves,
          sanMoves: sanMoves,
          playerIsWhite: true,
          pgn: pgn,
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var ply = 1; ply < positions.length; ply++) {
      await tester.tap(find.byKey(const ValueKey('next-move-button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'failed at ply $ply');
    }

    await tester.tap(find.byKey(const ValueKey('graph-tab')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisGraph), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(AnalysisGraph)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkmate evaluation rebuild survives on Android', (
    tester,
  ) async {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const checkmate =
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, checkmate],
          uciMoves: const ['d8h4'],
          sanMoves: const ['Qh4#'],
          playerIsWhite: true,
          pgn: '1. f3 e5 2. g4 Qh4#',
          onHome: () {},
          evaluator: (fen) async => fen == checkmate
              ? const StockfishReview(0, '(none)', mate: -1)
              : const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-move-button')));
    await tester.pumpAndSettle();

    expect(find.text('#-1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  Future<void> waitFor(WidgetTester tester, bool Function() condition) async {
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (condition()) return;
    }
    fail('Android screen or engine did not finish within 30 seconds');
  }

  Future<void> openRecent(WidgetTester tester, String title) async {
    final recent = find.text('Recent games');
    await tester.ensureVisible(recent);
    await tester.tap(recent);
    await waitFor(tester, () => find.text(title).evaluate().isNotEmpty);
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'completed Chessnut game in Android Recent games keeps board mode off',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await ActiveSessionStore.clear();
      final store = await ActiveSessionStore.repository;
      await store.deleteMany((await store.recent()).map((game) => game.id));
      await ActiveSessionStore.save({
        'type': 'game',
        'recentState': 'completed',
        'pgn': '[Event "Chessnut completed regression"]\n[Result "0-1"]\n1. f3 e5 2. g4 Qh4# 0-1',
        'electronicBoard': 'chessnut-go',
        'pendingPhysicalMaiaMove': 'd8h4',
      });
      await ActiveSessionStore.clear();
      final board = SimulatedElectronicBoard();
      await tester.pumpWidget(
        MaterialApp(home: GamePage(electronicBoardTransport: board)),
      );
      await waitFor(
        tester,
        () => find.text('Recent games').evaluate().isNotEmpty,
      );
      await openRecent(tester, 'Chessnut completed regression');
      await waitFor(
        tester,
        () => find.text('Black is victorious').evaluate().isNotEmpty,
      );
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsNothing,
      );
      expect(board.connects, 0);
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-home-button')));
      await waitFor(
        tester,
        () => find.text('Recent games').evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('chessnut-go-toggle')),
            )
            .value,
        isFalse,
      );
      // Selecting another completed record must not inherit the old result-dialog flag.
      await openRecent(tester, 'Chessnut completed regression');
      await waitFor(
        tester,
        () => find.text('Black is victorious').evaluate().isNotEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await board.close();
    },
  );

  testWidgets(
    'Android Recent game switches to phone with real Maia and retains its archive identity',
    (tester) async {
      await ActiveSessionStore.clear();
      await ActiveSessionStore.save({
        'type': 'game',
        'recentState': 'incomplete',
        'pgn': '[Event "Chessnut phone regression"]\n1. e4 e5 *',
        'electronicBoard': 'chessnut-go',
        'clockPaused': true,
        'playerIsWhite': true,
        'timePreset': 'unlimited',
      });
      await ActiveSessionStore.clear();
      final before = (await ActiveSessionStore.recent()).singleWhere(
        (game) => game.title == 'Chessnut phone regression',
      );
      final board = SimulatedElectronicBoard();
      await tester.pumpWidget(
        MaterialApp(home: GamePage(electronicBoardTransport: board)),
      );
      await waitFor(
        tester,
        () => find.text('Recent games').evaluate().isNotEmpty,
      );
      await openRecent(tester, 'Chessnut phone regression');
      await waitFor(
        tester,
        () => find.text('Play in app').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Play in app'));
      await tester.pumpAndSettle();
      final screenBoard = tester.widget<cg.Chessboard>(
        find.byType(cg.Chessboard),
      );
      expect(screenBoard.controller.interactive, isTrue);
      screenBoard.onMove!(dc.NormalMove.fromUci('g1f3'));
      await waitFor(
        tester,
        () =>
            tester
                .widget<cg.Chessboard>(find.byType(cg.Chessboard))
                .controller
                .game
                .sideToMove ==
            dc.Side.white,
      );
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (((await ActiveSessionStore.load())?['uciMoves'] as List?)?.length ==
            4) {
          break;
        }
      }
      final saved = (await ActiveSessionStore.load())!;
      expect(saved['uciMoves'], hasLength(4));
      expect((saved['uciMoves'] as List).take(3), ['e2e4', 'e7e5', 'g1f3']);
      expect(saved['electronicBoard'], isNull);
      await tester.tap(find.byKey(const ValueKey('game-home-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await waitFor(
        tester,
        () => find.text('Recent games').evaluate().isNotEmpty,
      );
      final after = (await ActiveSessionStore.recent()).singleWhere(
        (game) => game.title == 'Chessnut phone regression',
      );
      expect(after.id, before.id);
      expect(after.data['electronicBoard'], isNull);
      await openRecent(tester, 'Chessnut phone regression');
      await waitFor(
        tester,
        () => find.byType(cg.Chessboard).evaluate().isNotEmpty,
      );
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsNothing,
      );
      expect(
        tester
            .widget<cg.Chessboard>(find.byType(cg.Chessboard))
            .controller
            .interactive,
        isTrue,
      );
      expect(board.connects, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await board.close();
    },
  );
}
