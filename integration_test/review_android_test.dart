import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';

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
      if (panel.evaluate().isNotEmpty && analyzing.evaluate().isEmpty) return;
    }
    fail('real Stockfish evaluation did not finish within 24 seconds');
  }

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
      await tester.tap(find.byIcon(Icons.chevron_right));
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
    await tester.tap(find.byTooltip('Computer analysis'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    for (var i = 0; i < 600; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(AnalysisGraph).evaluate().isNotEmpty) break;
    }
    expect(find.textContaining('Stockfish failed:'), findsNothing);
    expect(find.byType(AnalysisGraph), findsOneWidget);
    for (final alignment in const [-0.9, 0.0, 0.9]) {
      final rect = tester.getRect(find.byType(AnalysisGraph));
      await tester.tapAt(
        Offset(rect.center.dx + alignment * rect.width / 2, rect.center.dy),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
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
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'failed at ply $ply');
    }

    await tester.tap(find.byTooltip('Computer analysis'));
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
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('#-1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
