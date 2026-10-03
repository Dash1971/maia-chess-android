import 'dart:convert';
import 'dart:io';
import 'package:chess/chess.dart' as chess;

void main(List<String> args) {
  final cases = jsonDecode(File(args.single).readAsStringSync()) as List;
  final rows = <Map<String, dynamic>>[];
  for (final c in cases) {
    final game = chess.Chess.fromFEN(c['fen']);
    for (final dynamic raw in c['moves_uci']) {
      final uci = raw as String;
      if (!game.move({
        'from': uci.substring(0, 2),
        'to': uci.substring(2, 4),
        if (uci.length > 4) 'promotion': uci.substring(4),
      })) {
        throw StateError('Illegal Dart move: $uci');
      }
    }
    List<String>? outcome;
    if (game.in_checkmate) {
      outcome = [game.turn == chess.Chess.WHITE ? '0-1' : '1-0', 'checkmate'];
    } else if (game.half_moves >= 100) {
      outcome = ['1/2-1/2', 'fifty_moves_actual'];
    } else if (game.in_stalemate) {
      outcome = ['1/2-1/2', 'stalemate'];
    } else if (game.insufficient_material) {
      outcome = ['1/2-1/2', 'insufficient_material'];
    } else if (game.in_threefold_repetition) {
      outcome = ['1/2-1/2', 'threefold_repetition_actual'];
    }
    rows.add({'id': c['id'], 'outcome': outcome, 'game_over': game.game_over,
      'raw_fen': game.fen});
  }
  stdout.writeln(jsonEncode(rows));
}
