import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('move vocabulary matches Maia-3 ordering', () {
    expect(MaiaEncoding.moveIndex('e2e4', false), 796);
    expect(MaiaEncoding.moveIndex('e7e5', true), 796);
    expect(MaiaEncoding.moveIndex('a7a8q', false), 4096);
    expect(MaiaEncoding.moveIndex('h7h8n', false), 4351);
  });

  test('tokenization mirrors the side-to-move perspective', () {
    const whiteFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const blackFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1';
    final white = MaiaEncoding.tokenizeFen(whiteFen);
    final black = MaiaEncoding.tokenizeFen(blackFen);
    expect(white[3], 1); // White rook on a1.
    expect(white[56 * 12 + 9], 1); // Black rook on a8.
    expect(black[3], 1); // Black-to-move is mirrored and colours are swapped.
    expect(black[56 * 12 + 9], 1);
  });

  test('historical tensor has the exported model shape', () {
    const fen = '8/8/8/8/8/8/8/K6k w - - 0 1';
    expect(MaiaEncoding.historicalTokens([fen]), hasLength(64 * 97));
  });
}
