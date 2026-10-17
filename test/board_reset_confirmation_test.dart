import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  late Duration now;
  late BoardResetConfirmation confirmation;
  BoardResetPress press({int game = 1, String board = 'connection-1'}) =>
      confirmation.press(generation: game, connection: board);
  setUp(() {
    now = Duration.zero;
    confirmation = BoardResetConfirmation(elapsed: () => now);
  });
  test(
    'first press is non-destructive and second is consumed exactly once',
    () {
      expect(press(), BoardResetPress.armed);
      now = const Duration(milliseconds: 1000);
      expect(press(), BoardResetPress.confirmed);
      now = const Duration(milliseconds: 2000);
      expect(press(), BoardResetPress.ignored);
    },
  );
  for (final milliseconds in [2499, 2500, 2501]) {
    test('confirmation boundary $milliseconds milliseconds', () {
      press();
      now = Duration(milliseconds: milliseconds);
      expect(
        press(),
        milliseconds <= 2500
            ? BoardResetPress.confirmed
            : BoardResetPress.armed,
      );
    });
  }
  test('duplicate bursts extend quiet interval without confirming', () {
    press();
    for (final milliseconds in [1, 100, 499, 800, 1200]) {
      now = Duration(milliseconds: milliseconds);
      expect(press(), BoardResetPress.ignored);
    }
    now = const Duration(milliseconds: 1700);
    expect(press(), BoardResetPress.confirmed);
  });
  test('documented held-button repeats never confirm', () {
    press();
    for (final seconds in [3200, 6400, 9600]) {
      now = Duration(milliseconds: seconds);
      expect(press(), BoardResetPress.armed);
    }
  });
  test('cancellation disarms and requires two fresh presses', () {
    press();
    confirmation.disarm();
    now = const Duration(seconds: 1);
    expect(press(), BoardResetPress.armed);
    now = const Duration(seconds: 2);
    expect(press(), BoardResetPress.confirmed);
  });
  test('game and connection replacements cannot confirm pending request', () {
    press();
    now = const Duration(seconds: 1);
    expect(press(game: 2), BoardResetPress.armed);
    now = const Duration(seconds: 2);
    expect(press(game: 2, board: 'connection-2'), BoardResetPress.armed);
  });
}
