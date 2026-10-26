part of '../main.dart';

const maiaMinimumRating = 600;
const maiaMaximumRating = 2600;
const maiaRatingStep = 100;
const maiaRatingDivisions =
    (maiaMaximumRating - maiaMinimumRating) ~/ maiaRatingStep;

int normalizeMaiaRating(int rating) =>
    rating.clamp(maiaMinimumRating, maiaMaximumRating);

int? _decodeMaiaRating(Object? value) {
  if (value is! int) return null;
  if (value == 500) return maiaMinimumRating;
  return value >= maiaMinimumRating && value <= maiaMaximumRating
      ? value
      : null;
}

int _readMaiaRatingPreference(
  SharedPreferences preferences,
  String key, {
  required int fallback,
}) {
  final rating = _readValidatedPreference<int>(
    preferences,
    key,
    fallback: fallback,
    decode: (value) {
      if (value is int && value == 500) {
        unawaited(_migrateMaiaRatingPreference(preferences, key));
        return maiaMinimumRating;
      }
      return _decodeMaiaRating(value);
    },
  );
  return rating;
}

Future<void> _migrateMaiaRatingPreference(
  SharedPreferences preferences,
  String key,
) async {
  try {
    await preferences.setInt(key, maiaMinimumRating);
  } catch (error, stackTrace) {
    await AppDiagnostics.record('preference-migrate:$key', error, stackTrace);
  }
}

class MaiaMoveProbability {
  const MaiaMoveProbability({required this.uci, required this.probability});

  final String uci;
  final double probability;
}

class MaiaPositionAnalysis {
  const MaiaPositionAnalysis(
    this.moves, {
    this.hasRawProbabilities = true,
    this.outcome,
  });

  factory MaiaPositionAnalysis.single(String uci) => MaiaPositionAnalysis([
    MaiaMoveProbability(uci: uci, probability: 1),
  ], hasRawProbabilities: false);

  final List<MaiaMoveProbability> moves;
  final bool hasRawProbabilities;
  final MaiaOutcome? outcome;

  String? get topMove => moves.firstOrNull?.uci;
}

class MaiaEncoding {
  static final Random _random = Random();

  /// Effective eight-board input, oldest first. Each board uses its own
  /// side-to-move orientation, matching the validated upstream encoder.
  static List<String> historyWindow(
    List<String> positions, {
    bool useMoveHistory = false,
  }) {
    if (positions.isEmpty) throw ArgumentError.value(positions, 'positions');
    final window = useMoveHistory
        ? positions.skip(max(0, positions.length - 8)).toList()
        : <String>[positions.last];
    return List.unmodifiable([
      ...List<String>.filled(8 - window.length, window.first),
      ...window,
    ]);
  }

  static String historyKey(
    List<String> positions, {
    bool useMoveHistory = false,
  }) =>
      '${useMoveHistory ? "history" : "current"}\n${historyWindow(positions, useMoveHistory: useMoveHistory).join("\n")}';

  static Float32List historicalTokens(
    List<String> positions, {
    bool useMoveHistory = false,
  }) {
    // History is an experimental input choice; off retains the released
    // engine's current-board repetition. Observed opening copying with history
    // is model behavior, not evidence of an orientation bug.
    final encoded = <String, List<double>>{};
    final boards = historyWindow(positions, useMoveHistory: useMoveHistory)
        .map((fen) => encoded.putIfAbsent(fen, () => tokenizeFen(fen)))
        .toList(growable: false);
    return Float32List.fromList(
      List<double>.generate(64 * 97, (index) {
        final square = index ~/ 97;
        final channel = index % 97;
        if (channel == 96) return 0;
        return boards[channel ~/ 12][square * 12 + channel % 12];
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
    Random? random,
    void Function(Map<String, Object?>)? onSample,
  }) {
    final safeTopP = topP.clamp(0.0, 1.0);
    if (temperature <= 0) {
      final selected = legalMoves.reduce((best, move) {
        final bestIndex = moveIndex(uci(best), game.turn == chess.Color.BLACK);
        final moveIndexValue = moveIndex(
          uci(move),
          game.turn == chess.Color.BLACK,
        );
        return logits[moveIndexValue] > logits[bestIndex] ? move : best;
      });
      onSample?.call(
        _samplingTrace(game, legalMoves, temperature, topP, selected, null),
      );
      return selected;
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
      // Include the crossing move: the nucleus is the smallest prefix whose
      // probability mass reaches topP, rather than the prefix below it.
      nucleus.add(item);
      cumulative += item.weight / fullTotal;
      if (safeTopP < 1.0 && cumulative >= safeTopP) break;
    }
    final nucleusTotal = nucleus.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    final draw = (random ?? _random).nextDouble();
    var target = draw * nucleusTotal;
    var lower = 0.0;
    void record(chess.Move selected) {
      if (onSample == null) return;
      onSample(
        _samplingTrace(game, legalMoves, temperature, topP, selected, {
          'draw': draw,
          'target': draw * nucleusTotal,
          'total': nucleusTotal,
          'lower': lower,
          'upper': lower + nucleus.firstWhere((v) => v.move == selected).weight,
          'nucleusCount': nucleus.length,
          'weightedOrder': weighted
              .map((v) => {'uci': uci(v.move), 'weight': v.weight})
              .toList(),
        }),
      );
    }

    for (final item in nucleus) {
      target -= item.weight;
      if (target <= 0) {
        record(item.move);
        return item.move;
      }
      lower += item.weight;
    }
    lower -= nucleus.last.weight;
    record(nucleus.last.move);
    return nucleus.last.move;
  }

  static Map<String, Object?> _samplingTrace(
    chess.Chess game,
    List<chess.Move> moves,
    double temperature,
    double topP,
    chess.Move selected,
    Map<String, Object?>? random,
  ) => {
    'temperature': temperature,
    'topP': topP,
    'effectiveTemperature': temperature <= 0
        ? 0.0
        : temperature.clamp(0.001, 1.0),
    'effectiveTopP': topP.clamp(0.0, 1.0),
    'mode': random == null ? 'argmax' : 'random',
    'selected': uci(selected),
    'legalOrder': moves
        .map(
          (m) => {
            'uci': uci(m),
            'index': moveIndex(uci(m), game.turn == chess.Color.BLACK),
          },
        )
        .toList(),
    'random': random,
  };

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

  /// Raw Maia policy probabilities normalized over legal moves only.
  ///
  /// Temperature and Top-P deliberately do not apply here: this is an
  /// explanation of the model's policy, not the configured move sampler.
  static List<MaiaMoveProbability> legalMoveProbabilities(
    chess.Chess game,
    List<double> logits,
  ) {
    final legalMoves = game
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .toList(growable: false);
    if (legalMoves.isEmpty) return const [];
    final scored = legalMoves
        .map((move) {
          final moveUci = uci(move);
          return (
            uci: moveUci,
            logit: logits[moveIndex(moveUci, game.turn == chess.Color.BLACK)],
          );
        })
        .toList(growable: false);
    final maxLogit = scored.map((item) => item.logit).reduce(max);
    final weights = scored
        .map((item) => exp(item.logit - maxLogit))
        .toList(growable: false);
    final total = weights.reduce((a, b) => a + b);
    final probabilities = <MaiaMoveProbability>[
      for (var index = 0; index < scored.length; index++)
        MaiaMoveProbability(
          uci: scored[index].uci,
          probability: weights[index] / total,
        ),
    ];
    probabilities.sort((a, b) {
      final probabilityOrder = b.probability.compareTo(a.probability);
      return probabilityOrder != 0 ? probabilityOrder : a.uci.compareTo(b.uci);
    });
    return List.unmodifiable(probabilities);
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
