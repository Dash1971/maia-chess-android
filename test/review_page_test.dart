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
          entries: const [AnalysisEntry('b4', 0, 0, 0.2, 'e2e4')],
          stockfishReviews: const [
            StockfishReview(0, 'e2e4'),
            StockfishReview(10, 'e7e5'),
          ],
          playerIsWhite: true,
          maiaElo: 1500,
          pgn: '1. b4',
          onHome: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Game review'), findsOneWidget);
  });
}
