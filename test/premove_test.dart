import 'dart:async';
import 'dart:typed_data';

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('allows a premove recapture onto a currently friendly piece', () {
    const fen = '4k3/8/8/8/8/3B4/4P3/4K3 b - - 0 1';

    expect(isPremoveDestination(fen, 'd3', 'e2'), isTrue);
  });

  test('rejects an own-piece tap that is not valid premove geometry', () {
    const fen = '4k3/8/8/8/8/3B4/4P3/4K3 b - - 0 1';

    expect(isPremoveDestination(fen, 'd3', 'e1'), isFalse);
  });

  test('does not request another Maia move after a mating premove', () {
    expect(
      shouldRequestMaiaReply(premovePlayed: true, gameOver: true),
      isFalse,
    );
  });

  test('requests a Maia reply after a non-terminal premove', () {
    expect(
      shouldRequestMaiaReply(premovePlayed: true, gameOver: false),
      isTrue,
    );
  });

  testWidgets('a mating Rxe1 premove records a Black win, not a draw', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await ActiveSessionStore.clear();
    final pendingMaia = Completer<Float32List>();
    const beforeMaiaMove = '8/8/8/8/8/6k1/P3r3/4R1K1 w - - 0 1';

    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          startingFen: beforeMaiaMove,
          startingSide: PlayerSide.black,
          maiaEvaluator: (_, _) => pendingMaia.future,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    board.controller.premove = dc.NormalMove.fromUci('e2e1');

    final policy = Float32List(4352)..fillRange(0, 4352, -100);
    policy[MaiaEncoding.moveIndex('a2a3', false)] = 100;
    pendingMaia.complete(policy);
    await tester.pumpAndSettle();

    expect(find.text('Black is victorious'), findsOneWidget);
    expect(find.text('The game is a draw'), findsNothing);
    final saved = await ActiveSessionStore.load();
    expect(saved!['pgn'], contains('Rxe1#'));
    expect(saved['pgn'], contains('[Result "0-1"]'));
  });
}
