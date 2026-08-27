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
