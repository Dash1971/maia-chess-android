import 'dart:convert';
import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('all 38 official upstream history tensors match exactly', () {
    // Sparse fixture copied from the published study's upstream-reference.json
    // and upstream-tensors.json, rather than produced by the Dart encoder.
    final cases = jsonDecode(
      File('test/fixtures/maia_history_upstream.json').readAsStringSync(),
    ) as List;
    expect(cases, hasLength(38));
    for (final item in cases) {
      final tokens = MaiaEncoding.historicalTokens(
        (item['history'] as List).cast<String>(),
        useMoveHistory: item['mode'] == 'H',
      );
      final expected = List<double>.filled(64 * 97, 0);
      for (final index in item['ones'] as List) {
        expected[index as int] = 1;
      }
      expect(tokens, expected, reason: '${item['id']} ${item['mode']}');
    }
  });

  test('cache identity isolates mode and same-FEN different histories', () {
    final first = chess.Chess();
    final second = chess.Chess();
    final a = [first.fen];
    final b = [second.fen];
    for (final san in ['Nf3', 'Nf6', 'Ng1', 'Ng8']) {
      first.move(san);
      a.add(first.fen);
    }
    for (final san in ['Nc3', 'Nc6', 'Nb1', 'Nb8']) {
      second.move(san);
      b.add(second.fen);
    }
    expect(a.last, b.last);
    expect(MaiaEncoding.historyKey(a), MaiaEncoding.historyKey(b));
    expect(
      MaiaEncoding.historyKey(a, useMoveHistory: true),
      isNot(MaiaEncoding.historyKey(b, useMoveHistory: true)),
    );
    expect(
      MaiaEncoding.historyKey(a),
      isNot(MaiaEncoding.historyKey(a, useMoveHistory: true)),
    );
  });

  test('short history pads earliest board, long history keeps last eight', () {
    final game = chess.Chess();
    final positions = [game.fen];
    for (final san in [
      'd4',
      'd5',
      'e3',
      'e6',
      'Bd3',
      'Bd6',
      'f4',
      'f5',
      'Nf3',
      'Nf6',
      'O-O',
      'O-O',
    ]) {
      expect(game.move(san), isTrue);
      positions.add(game.fen);
    }
    expect(
      MaiaEncoding.historyWindow(
        positions.take(2).toList(),
        useMoveHistory: true,
      ),
      [...List.filled(7, positions.first), positions[1]],
    );
    expect(
      MaiaEncoding.historyWindow(positions, useMoveHistory: true),
      positions.sublist(positions.length - 8),
    );
    expect(
      MaiaEncoding.historyWindow([positions.last], useMoveHistory: true),
      List.filled(8, positions.last),
    );
  });
}
