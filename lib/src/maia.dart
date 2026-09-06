part of '../main.dart';

class MaiaEncoding {
  static final Random _random = Random();

  static Float32List historicalTokens(List<String> positions) {
    // Maia-3 exposes reconstructed move history as an optional UCI mode. Its
    // released engine default repeats the current position in all eight board
    // slots. Alternating independently mirrored historical FENs can otherwise
    // create a strong false copy-the-opponent signal when Maia plays Black.
    final current = tokenizeFen(positions.last);
    return Float32List.fromList(
      List<double>.generate(64 * 97, (index) {
        final square = index ~/ 97;
        final channel = index % 97;
        if (channel == 96) return 0;
        final pieceChannel = channel % 12;
        return current[square * 12 + pieceChannel];
      }),
    );
  }

  static List<double> tokenizeFen(String fen) {
    final parts = fen.split(' ');
    final blackToMove = parts[1] == 'b';
    final result = List<double>.filled(64 * 12, 0);
    final ranks = parts[0].split('/');
    for (var fenRank = 0; fenRank < 8; fenRank++) {
      var file = 0;
      for (final symbol in ranks[fenRank].split('')) {
        final empty = int.tryParse(symbol);
        if (empty != null) {
          file += empty;
          continue;
        }
        final originalWhite = symbol == symbol.toUpperCase();
        final type = symbol.toLowerCase();
        final originalRank = 8 - fenRank;
        final rank = blackToMove ? 9 - originalRank : originalRank;
        final white = blackToMove ? !originalWhite : originalWhite;
        final square = file + (rank - 1) * 8;
        final piece = const {
          'p': 0,
          'n': 1,
          'b': 2,
          'r': 3,
          'q': 4,
          'k': 5,
        }[type]!;
        result[square * 12 + piece + (white ? 0 : 6)] = 1;
        file++;
      }
    }
    return result;
  }

  static chess.Move sampleLegalMove(
    chess.Chess game,
    List<chess.Move> legalMoves,
    List<double> logits, {
    double temperature = 1.0,
    double topP = 1.0,
  }) {
    final safeTopP = topP.clamp(0.0, 1.0);
    if (temperature <= 0) {
      return legalMoves.reduce((best, move) {
        final bestIndex = moveIndex(uci(best), game.turn == chess.Color.BLACK);
        final moveIndexValue = moveIndex(
          uci(move),
          game.turn == chess.Color.BLACK,
        );
        return logits[moveIndexValue] > logits[bestIndex] ? move : best;
      });
    }
    final safeTemperature = temperature.clamp(0.001, 1.0);
    final scored = legalMoves.map((move) {
      final uci =
          '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';
      return (
        move: move,
        logit:
            logits[moveIndex(uci, game.turn == chess.Color.BLACK)] /
            safeTemperature,
      );
    }).toList();
    final maxLogit = scored.map((item) => item.logit).reduce(max);
    final weighted =
        scored
            .map(
              (item) => (move: item.move, weight: exp(item.logit - maxLogit)),
            )
            .toList()
          ..sort((a, b) => b.weight.compareTo(a.weight));
    final fullTotal = weighted.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    final nucleus = <({chess.Move move, double weight})>[];
    var cumulative = 0.0;
    for (var index = 0; index < weighted.length; index++) {
      final item = weighted[index];
      cumulative += item.weight / fullTotal;
      if (index == 0 || safeTopP >= 1.0 || cumulative <= safeTopP) {
        nucleus.add(item);
      } else {
        break;
      }
    }
    final nucleusTotal = nucleus.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    var target = _random.nextDouble() * nucleusTotal;
    for (final item in nucleus) {
      target -= item.weight;
      if (target <= 0) return item.move;
    }
    return nucleus.last.move;
  }

  static ({double probability, String topMove}) reviewMove(
    chess.Chess game,
    String playedMove,
    List<double> logits,
  ) {
    final legalMoves = game.moves({'asObjects': true}).cast<chess.Move>();
    final scored = legalMoves.map((move) {
      final moveUci = uci(move);
      return (
        uci: moveUci,
        logit: logits[moveIndex(moveUci, game.turn == chess.Color.BLACK)],
      );
    }).toList();
    final maxLogit = scored.map((item) => item.logit).reduce(max);
    final weights = scored.map((item) => exp(item.logit - maxLogit)).toList();
    final total = weights.reduce((a, b) => a + b);
    var probability = 0.0;
    var bestIndex = 0;
    for (var i = 0; i < scored.length; i++) {
      if (scored[i].uci == playedMove) probability = weights[i] / total;
      if (weights[i] > weights[bestIndex]) bestIndex = i;
    }
    return (probability: probability, topMove: scored[bestIndex].uci);
  }

  static String uci(chess.Move move) =>
      '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';

  static int moveIndex(String uci, bool blackToMove) {
    final normalized = blackToMove ? mirrorMove(uci) : uci;
    if (normalized.length == 5) {
      final fromFile = _fileIndex(normalized[0]);
      final toFile = _fileIndex(normalized[2]);
      final piece = const {'q': 0, 'r': 1, 'b': 2, 'n': 3}[normalized[4]]!;
      return 4096 + ((fromFile * 8 + toFile) * 4 + piece);
    }
    return _squareIndex(normalized.substring(0, 2)) * 64 +
        _squareIndex(normalized.substring(2, 4));
  }

  static String mirrorMove(String uci) {
    String mirrorSquare(String square) =>
        '${square[0]}${9 - int.parse(square[1])}';
    return '${mirrorSquare(uci.substring(0, 2))}${mirrorSquare(uci.substring(2, 4))}${uci.length == 5 ? uci[4] : ''}';
  }

  static int _fileIndex(String file) => file.codeUnitAt(0) - 'a'.codeUnitAt(0);
  static int _squareIndex(String square) =>
      _fileIndex(square[0]) + (int.parse(square[1]) - 1) * 8;
}
