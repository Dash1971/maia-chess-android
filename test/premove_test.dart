import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

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
}
