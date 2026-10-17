import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  String position(String turn, int number) =>
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR $turn KQkq - 0 $number';
  test('five full moves for both colors, including configured argmax', () {
    for (final temperature in [0.0, 0.5, 1.0]) {
      final settings = MaiaPlaySettings(
        temperature: temperature,
        topP: 0.95,
        maxOpeningVariety: true,
      );
      for (final side in ['w', 'b']) {
        for (final number in [1, 4, 5, 6, 20, 100]) {
          final actual = settings.forFen(position(side, number));
          expect(actual.opening, number <= 5);
          expect(actual.temperature, number <= 5 ? 1.0 : temperature);
          expect(actual.topP, number <= 5 ? 1.0 : 0.95);
        }
      }
    }
  });
  test('off and malformed move counters never enable opening override', () {
    const off = MaiaPlaySettings(temperature: 0.0, topP: 0.0);
    expect(off.forFen(chess.Chess.DEFAULT_POSITION).temperature, 0.0);
    const on = MaiaPlaySettings(
      temperature: 0.5,
      topP: 0.9,
      maxOpeningVariety: true,
    );
    for (final fen in ['bad', position('w', 0), position('w', -1)]) {
      expect(on.forFen(fen).opening, false);
    }
  });
  test('takeback across boundary derives phase from actual chess position', () {
    final game = chess.Chess.fromFEN(position('b', 5));
    const settings = MaiaPlaySettings(
      temperature: 0.0,
      topP: 0.0,
      maxOpeningVariety: true,
    );
    expect(settings.forFen(game.fen).opening, true);
    expect(game.move('e5'), true);
    expect(settings.forFen(game.fen).opening, false);
    game.undo();
    expect(settings.forFen(game.fen).opening, true);
    expect(settings.temperature, 0.0);
  });
  test(
    'saved configuration survives preference changes; old/invalid stays fixed',
    () {
      const original = MaiaPlaySettings(
        temperature: 0.5,
        topP: 0.95,
        maxOpeningVariety: true,
      );
      final restored = MaiaPlaySettings.restore(
        original.toJson(),
        fallbackTemperature: 0,
        fallbackTopP: 0,
      );
      expect(restored.toJson(), original.toJson());
      for (final invalid in [
        null,
        true,
        {},
        {'version': 2},
        {...original.toJson(), 'temperature': double.nan},
        {...original.toJson(), 'topP': 1.1},
        {...original.toJson(), 'maxOpeningVariety': 'true'},
      ]) {
        final legacy = MaiaPlaySettings.restore(
          invalid,
          fallbackTemperature: 0.5,
          fallbackTopP: 0.95,
        );
        expect(legacy.maxOpeningVariety, false);
        expect(legacy.forFen(chess.Chess.DEFAULT_POSITION).temperature, 0.5);
        expect(legacy.topP, 0.95);
      }
    },
  );
}
