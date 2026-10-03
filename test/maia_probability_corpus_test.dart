import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('raw distribution matches direct softmax across legal-move edge cases and seeded games', () {
    var checked = 0;
    final logits = List<double>.generate(4352, (i) => sin(i * 0.17) * 5);
    void check(chess.Chess game) {
      final legal = game.moves({'asObjects': true}).cast<chess.Move>().toList();
      final actual = MaiaEncoding.legalMoveProbabilities(game, logits);
      expect(
        actual.map((x) => x.uci).toSet(),
        legal.map(MaiaEncoding.uci).toSet(),
        reason: game.fen,
      );
      expect(actual.length, legal.length);
      if (legal.isNotEmpty) {
        final weights = <String, double>{
          for (final move in legal)
            MaiaEncoding.uci(move): exp(
              logits[MaiaEncoding.moveIndex(
                MaiaEncoding.uci(move),
                game.turn == chess.Color.BLACK,
              )],
            ),
        };
        final total = weights.values.reduce((a, b) => a + b);
        expect(
          actual.fold<double>(0, (sum, x) => sum + x.probability),
          closeTo(1, 1e-12),
        );
        for (var i = 0; i < actual.length; i++) {
          expect(actual[i].probability.isFinite, isTrue);
          expect(
            actual[i].probability,
            closeTo(weights[actual[i].uci]! / total, 1e-12),
          );
          if (i > 0) {
            expect(
              actual[i - 1].probability,
              greaterThanOrEqualTo(actual[i].probability),
            );
          }
        }
      }
      checked++;
    }

    for (final fen in [
      'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
      '4k3/P7/8/8/8/8/8/4K3 w - - 0 1',
      '4k3/8/8/8/8/8/p7/4K3 b - - 0 1',
      '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
      '4k3/8/8/8/3Pp3/8/8/4K3 b - d3 0 1',
      '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1',
      '7k/5K2/6Q1/8/8/8/8/8 b - - 0 1',
    ]) {
      check(chess.Chess.fromFEN(fen));
    }
    final random = Random(20260928);
    for (var run = 0; run < 10; run++) {
      final game = chess.Chess();
      for (var ply = 0; ply < 100; ply++) {
        check(game);
        final legal = game.moves();
        if (legal.isEmpty || game.game_over) break;
        expect(game.move(legal[random.nextInt(legal.length)]), isTrue);
      }
    }
    expect(checked, greaterThan(900));
    // ignore: avoid_print
    print(
      'Validated $checked positions, including both colors, castling, en passant, promotions, mate and stalemate.',
    );
  });
}
