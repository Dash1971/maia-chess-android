import 'dart:async';
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('diagnostics persist exception evidence and version metadata', () async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Maia Chess',
      packageName: 'com.dash1971.maia_chess',
      version: '1.6.6',
      buildNumber: '19',
      buildSignature: '',
    );
    await AppDiagnostics.record(
      'test-source',
      StateError('diagnostic-test-error'),
      StackTrace.fromString('diagnostic-test-stack'),
    );

    final report = await AppDiagnostics.report();
    expect(report, contains('version=1.6.6 build=19'));
    expect(report, contains('[test-source]'));
    expect(report, contains('diagnostic-test-error'));
    expect(report, contains('diagnostic-test-stack'));
  });

  testWidgets('About shows the package version instead of a hard-coded value', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Maia Chess',
      packageName: 'com.dash1971.maia_chess',
      version: '1.6.6',
      buildNumber: '19',
      buildSignature: '',
    );
    await tester.pumpWidget(const MaiaChessApp());
    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();

    expect(find.text('1.6.6'), findsOneWidget);
    expect(find.text('1.6.4'), findsNothing);
    expect(find.text('Copy diagnostics'), findsOneWidget);
  });

  testWidgets('review page lays out inside a vertical scroll view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const after =
        'rnbqkbnr/pppp1ppp/8/4p3/1P6/8/P1PPPPPP/RNBQKBNR w KQkq - 0 2';
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, after],
          uciMoves: const ['b2b4'],
          sanMoves: const ['b4'],
          playerIsWhite: true,
          pgn: '1. b4',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Game review'), findsOneWidget);
    expect(find.text('Starting position  ·  0/1'), findsOneWidget);
    expect(find.text('Computer analysis graph'), findsOneWidget);
    expect(find.byTooltip('Flip board'), findsOneWidget);
    expect(find.text('+0.0'), findsOneWidget);

    await tester.tap(find.text('Computer analysis graph'));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisGraph), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('evaluation bar uses signed Lichess-style score', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 300, child: EvaluationBar(evaluation: -200)),
        ),
      ),
    );

    expect(find.text('-2.0'), findsOneWidget);
  });

  testWidgets('evaluation bar preserves signed mate distance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: EvaluationBar(evaluation: 0, mate: -3),
          ),
        ),
      ),
    );

    expect(find.text('#-3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid engine bestmove cannot crash review rendering', (
    tester,
  ) async {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start],
          uciMoves: const [],
          sanMoves: const [],
          playerIsWhite: true,
          pgn: '',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, '0000'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(cg.StaticChessboard), findsOneWidget);
  });

  testWidgets('full graph awaits an evaluation already in flight', (
    tester,
  ) async {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const after = 'rnbqkbnr/pppp1ppp/8/4p3/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 2';
    final firstEvaluation = Completer<StockfishReview>();
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, after],
          uciMoves: const ['e7e5'],
          sanMoves: const ['e5'],
          playerIsWhite: true,
          pgn: '1... e5',
          onHome: () {},
          evaluator: (fen) => fen == start
              ? firstEvaluation.future
              : Future.value(const StockfishReview(-40, 'g1f3')),
        ),
      ),
    );
    await tester.pump();
    final graphAction = find.text('Computer analysis graph');
    await tester.ensureVisible(graphAction);
    await tester.tap(graphAction);
    await tester.pump();
    expect(find.byType(AnalysisGraph), findsNothing);

    firstEvaluation.complete(const StockfishReview(120, 'e2e4'));
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(AnalysisGraph),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.painter! as AnalysisGraphPainter;
    expect(painter.scores.first.evaluation, 120);
  });

  testWidgets('graph selection is bounded by per-ply SAN labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const position = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: List.filled(100, position),
          uciMoves: List.filled(99, 'e2e4'),
          // Reproduces v1.6.6 diagnostics: graph/position data reached ply
          // 98 while the grouped SAN list only had indices 0..60.
          sanMoves: List.filled(61, 'e4'),
          playerIsWhite: true,
          pgn: '',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer analysis graph'));
    await tester.pumpAndSettle();

    final graph = find.byType(AnalysisGraph);
    final rect = tester.getRect(graph);
    await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
    await tester.pumpAndSettle();

    expect(find.textContaining('61/61'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('evaluation bar renders forced mate at both extremes', (
    tester,
  ) async {
    for (final mate in const [-1, 1]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: EvaluationBar(evaluation: 0, mate: mate),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'mate=$mate');
    }
  });

  testWidgets('stepping and graph selection survive a checkmate position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const beforeMate =
        'rnbqkbnr/pppppppp/8/8/8/5P2/PPPPP1PP/RNBQKBNR b KQkq - 0 1';
    const checkmate =
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';

    Future<StockfishReview> evaluator(String fen) async => fen == checkmate
        ? const StockfishReview(0, '(none)', mate: -1)
        : const StockfishReview(25, 'e2e4');

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, beforeMate, checkmate],
          uciMoves: const ['f2f3', 'd8h4'],
          sanMoves: const ['f3', 'Qh4#'],
          playerIsWhite: true,
          pgn: '1. f3 e5 2. g4 Qh4#',
          onHome: () {},
          evaluator: evaluator,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('#-1'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Computer analysis graph'));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisGraph), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(AnalysisGraph)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('every next-move transition in the reported long game renders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(find.textContaining('${positions.length - 1}/'), findsOneWidget);
  });

  test('analysis graph fills black above and white below the curve', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    AnalysisGraphPainter(
      scores: const [StockfishReview(0, ''), StockfishReview(0, '')],
      selectedPly: 0,
    ).paint(canvas, const Size(200, 100));
    final image = await recorder.endRecording().toImage(200, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    Color pixelAt(int x, int y) {
      final offset = (y * 200 + x) * 4;
      return Color.fromARGB(
        bytes!.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );
    }

    expect(pixelAt(100, 25), const Color(0xff262421));
    expect(pixelAt(100, 75), const Color(0xffeeeeee));
  });

  test('checkmate position is handled without starting Stockfish', () async {
    const checkmate =
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';
    final review = await StockfishAnalyzer.instance.evaluate(checkmate);

    expect(review.mate, -1);
    expect(review.bestMove, '(none)');
    expect(review.whiteWinningChances, lessThan(-0.99));
  });

  testWidgets('material display preserves bishop versus knight imbalance', (
    tester,
  ) async {
    const fen = '4k3/8/8/8/8/8/8/2B1K1n1 w - - 0 1';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MaterialDifference(fen: fen)),
      ),
    );

    expect(find.text('♝'), findsOneWidget);
    expect(find.text('♘'), findsOneWidget);
  });
}
