import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

class QuantileRandom implements Random {
  QuantileRandom(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  bool nextBool() => throw UnsupportedError('not used');
  @override
  int nextInt(int max) => throw UnsupportedError('not used');
}

void main() {
  test('sampling matches probability-space quantiles across settings and sides', () {
    final rng = Random(20260910);
    var checked = 0;
    for (final fen in [
      chess.Chess.DEFAULT_POSITION,
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1',
      '7k/P7/8/8/8/8/7p/K7 w - - 0 1',
      '7k/P7/8/8/8/8/7p/K7 b - - 0 1',
    ]) {
      final game = chess.Chess.fromFEN(fen);
      final legal = game.moves({'asObjects': true}).cast<chess.Move>();
      for (var trial = 0; trial < 30; trial++) {
        final probabilities = List.generate(
          legal.length,
          (_) => .01 + rng.nextDouble(),
        );
        final order = List.generate(legal.length, (i) => i)
          ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));
        for (final temperature in [0.0, .05, .5, 1.0]) {
          final weights = temperature == 0
              ? <double>[]
              : order
                    .map(
                      (i) => pow(probabilities[i], 1 / temperature).toDouble(),
                    )
                    .toList();
          final total = weights.fold<double>(0, (a, b) => a + b);
          for (final topP in [0.0, .01, .5, .8, .9, 1.0]) {
            final allowed = <int>[];
            if (temperature == 0) {
              allowed.add(order.first);
            } else {
              // An item belongs to the nucleus when the mass before it is
              // below p. The first item is always included, including p = 0.
              var before = 0.0;
              for (var i = 0; i < order.length; i++) {
                if (i == 0 || topP == 1 || before / total < topP) {
                  allowed.add(order[i]);
                }
                before += weights[i];
              }
            }
            for (final quantile in [.000001, .2, .5, .8, .999999]) {
              var expected = allowed.first;
              if (temperature != 0) {
                final kept = allowed
                    .map(
                      (i) => pow(probabilities[i], 1 / temperature).toDouble(),
                    )
                    .toList();
                final target = quantile * kept.fold<double>(0, (a, b) => a + b);
                var cumulative = 0.0;
                for (var i = 0; i < allowed.length; i++) {
                  cumulative += kept[i];
                  if (cumulative >= target) {
                    expected = allowed[i];
                    break;
                  }
                }
              }
              for (final offset in [-1000.0, 0.0, 1000.0]) {
                final logits = List<double>.filled(4352, -10000);
                for (var i = 0; i < legal.length; i++) {
                  logits[MaiaEncoding.moveIndex(
                        MaiaEncoding.uci(legal[i]),
                        game.turn == chess.Color.BLACK,
                      )] =
                      log(probabilities[i]) + offset;
                }
                final actual = MaiaEncoding.sampleLegalMove(
                  game,
                  legal,
                  logits,
                  temperature: temperature,
                  topP: topP,
                  random: QuantileRandom(quantile),
                );
                expect(
                  MaiaEncoding.uci(actual),
                  MaiaEncoding.uci(legal[expected]),
                  reason:
                      '$fen trial=$trial T=$temperature P=$topP q=$quantile offset=$offset',
                );
                checked++;
              }
            }
          }
        }
      }
    }
    expect(checked, 43200);
  });
}
