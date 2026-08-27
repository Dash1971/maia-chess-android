import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
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
