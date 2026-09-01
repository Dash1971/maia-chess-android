import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('realistic MultiPV classification stays off the UI isolate', () async {
    final game = chess.Chess();
    final positions = <String>[game.fen];
    final uciMoves = <String>[];
    for (final san in const [
      'e4',
      'e5',
      'Nf3',
      'Nc6',
      'Bb5',
      'a6',
      'Ba4',
      'Nf6',
      'O-O',
      'Be7',
      'Re1',
      'b5',
      'Bb3',
      'd6',
      'c3',
      'O-O',
      'h3',
      'Nb8',
      'd4',
      'Nbd7',
      'c4',
      'c6',
      'cxb5',
      'axb5',
      'Nc3',
      'Bb7',
      'Bg5',
      'b4',
      'Nb1',
      'h6',
    ]) {
      final move = game
          .moves({'asObjects': true})
          .cast<chess.Move>()
          .firstWhere((candidate) {
            final copy = chess.Chess.fromFEN(game.fen)..move(candidate);
            return copy
                    .getHistory({'verbose': true})
                    .cast<Map<String, dynamic>>()
                    .last['san'] ==
                san;
          });
      uciMoves.add(MaiaEncoding.uci(move));
      expect(game.move(move), isTrue);
      positions.add(game.fen);
    }
    final scores = List.generate(
      positions.length,
      (index) => StockfishReview(
        index.isEven ? 20 : -20,
        'a2a3',
        lines: const [
          StockfishLine(evaluation: 20, moves: ['a2a3']),
          StockfishLine(evaluation: 10, moves: ['b2b3']),
        ],
      ),
    );
    final eventLoopTicked = Completer<void>();
    final stopwatch = Stopwatch()..start();
    final classification = MoveClassifier.classifyOffMainIsolate(
      scores: scores,
      positions: positions,
      uciMoves: uciMoves,
    );
    Timer.run(eventLoopTicked.complete);
    await eventLoopTicked.future.timeout(const Duration(seconds: 1));
    await classification.timeout(const Duration(seconds: 15));
    stopwatch.stop();
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
  });
}
