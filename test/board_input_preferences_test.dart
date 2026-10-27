// Exercise the same touch paths on the widget runner and Android integration runner.
// ignore_for_file: invalid_use_of_internal_member
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  for (final disabled in [false, true]) {
    testWidgets(
      'tap, drag and promotion survive aid changes (disabled=$disabled)',
      (tester) async {
        final prefs = BoardPreferencesController(
          read: () async => null,
          write: (_) async {},
        );
        final moves = <dc.Move>[];
        cg.GameData game(String fen, Map<dc.Square, Set<dc.Square>> valid) =>
            cg.GameData(
              fen: fen,
              playerSide: cg.PlayerSide.white,
              sideToMove: dc.Side.white,
              validMoves: valid,
            );
        final controller = cg.ChessboardController(
          game: game(dc.Chess.initial.fen, {
            dc.Square.e2: {dc.Square.e3, dc.Square.e4},
          }),
        );
        await tester.pumpWidget(
          BoardPreferencesScope(
            controller: prefs,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => cg.Chessboard(
                      size: 280,
                      orientation: dc.Side.white,
                      controller: controller,
                      settings: boardPreferencesOf(context).interactiveSettings,
                      onMove: (move, {bool? viaDragAndDrop}) => moves.add(move),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Offset point(dc.Square square) =>
            tester.getTopLeft(find.byType(cg.Chessboard)) +
            Offset((square.file + .5) * 35, (7 - square.rank + .5) * 35);
        await tester.tapAt(point(dc.Square.e2));
        await tester.pumpAndSettle();
        final boardState = tester.state(find.byType(cg.Chessboard));
        await prefs.select(
          BoardPreferences(
            board: BoardDesign.blue,
            pieces: PieceDesign.merida,
            coordinates: !disabled,
            legalMoves: !disabled,
            lastMove: !disabled,
            animation: !disabled,
            magnify: !disabled,
            dragTarget: cg.DragTargetKind.none,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          identical(boardState, tester.state(find.byType(cg.Chessboard))),
          isTrue,
        );
        expect(controller.highlightNotifier.selected, dc.Square.e2);
        await tester.tapAt(point(dc.Square.e4));
        await tester.pumpAndSettle();
        expect(moves.single.uci, 'e2e4');
        moves.clear();
        controller.updatePosition(
          game(dc.Chess.initial.fen, {
            dc.Square.e2: {dc.Square.e3, dc.Square.e4},
          }),
          animate: false,
        );
        await tester.pumpAndSettle();
        await tester.dragFrom(point(dc.Square.e2), const Offset(0, -70));
        await tester.pumpAndSettle();
        expect(moves.single.uci, 'e2e4');
        moves.clear();
        controller.updatePosition(
          game('7k/P7/8/8/8/8/8/7K w - - 0 1', {
            dc.Square.a7: {dc.Square.a8},
          }),
          animate: false,
        );
        await tester.pumpAndSettle();
        await tester.tapAt(point(dc.Square.a7));
        await tester.tapAt(point(dc.Square.a8));
        await tester.pumpAndSettle();
        expect(controller.pendingPromotionNotifier.value, isNotNull);
        await prefs.select(
          prefs.value.copyWith(coordinates: disabled, lastMove: disabled),
        );
        await tester.pumpAndSettle();
        expect(controller.pendingPromotionNotifier.value, isNotNull);
        final queen = find.byWidgetPredicate(
          (w) =>
              w is cg.PieceWidget &&
              w.piece.promoted &&
              w.piece.role == dc.Role.queen,
        );
        await tester.tap(queen);
        await tester.pumpAndSettle();
        expect(moves.single.uci, 'a7a8q');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        controller.dispose();
        prefs.dispose();
      },
    );
  }
}
