import 'dart:convert';
import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test(
    'legal moves and transitions agree with the independent chess corpus',
    () {
      final path =
          Platform.environment['MAIA_CHESS_CORPUS'] ??
          'test/fixtures/chess_oracle.json';
      final corpus = jsonDecode(File(path).readAsStringSync()) as Map;
      for (final row in (corpus['positions'] as List).cast<Map>()) {
        final fen = row['fen'] as String;
        AnalysisSession.validateFen(fen);
        final game = chess.Chess.fromFEN(fen);
        final legal = game.moves({'asObjects': true}).cast<chess.Move>();
        expect(
          legal.map(MaiaEncoding.uci).toList()..sort(),
          row['legal'],
          reason: fen,
        );
        expect(game.in_checkmate, row['checkmate'], reason: fen);
        expect(game.in_stalemate, row['stalemate'], reason: fen);
        if (row['move'] == null) continue;
        final move = legal.singleWhere(
          (move) => MaiaEncoding.uci(move) == row['move'],
        );
        final before = game.fen;
        expect(game.move(move), isTrue);
        expect(game.fen, row['after'], reason: fen);
        final observed = ChessnutProtocol.pieceMapFromFen(game.fen);
        expect(
          ChessnutProtocol.inferLegalMove(
            chess.Chess.fromFEN(before),
            observed,
          ),
          row['move'],
        );
        final imported = AnalysisSession.fromPgn(
          '[SetUp "1"]\n[FEN "$before"]\n\n${row['san']} *',
        );
        expect(imported.positions.last, game.fen);
        expect(
          AnalysisSession.fromPgn(imported.pgn).positions,
          imported.positions,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
