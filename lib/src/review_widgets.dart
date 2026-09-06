part of '../main.dart';

class ComputerAnalysisLine {
  const ComputerAnalysisLine({required this.positions, required this.uciMoves});

  final List<String> positions;
  final List<String> uciMoves;
}

enum MoveClassification {
  brilliant('!!', 'Brilliant', Color(0xff15aabf)),
  good('!', 'Good', Color(0xff12b886)),
  interesting('!?', 'Interesting', Color(0xff82c91e)),
  dubious('?!', 'Dubious', Color(0xfffab005)),
  mistake('?', 'Mistake', Color(0xfffd7e14)),
  blunder('??', 'Blunder', Color(0xfffa5252));

  const MoveClassification(this.symbol, this.label, this.color);

  final String symbol;
  final String label;
  final Color color;
}

class ClassifiedMove {
  const ClassifiedMove({
    required this.ply,
    required this.classification,
    this.moverIsWhite,
  });

  final int ply;
  final MoveClassification classification;
  final bool? moverIsWhite;
  bool get whiteMoved => moverIsWhite ?? ply.isOdd;
}

class MoveClassifier {
  // Adapted and translated to Dart from En Croissant v0.15.0's GPL-3.0
  // move-annotation and sacrifice-detection code:
  // https://github.com/franciscoBSalgueiro/en-croissant
  // Mobile Maia adds bounded search, background-isolate execution, and its
  // own review data/UI integration. See THIRD_PARTY_NOTICES.md.
  // This is a visual annotation heuristic, not the engine evaluation. Keep the
  // quiescence probe deliberately small so a long review can never monopolize
  // the UI; classification itself also runs outside the main isolate.
  static const _captureSearchNodeLimit = 64;

  static Future<List<ClassifiedMove>> classifyOffMainIsolate({
    required List<StockfishReview> scores,
    required List<String> positions,
    required List<String> uciMoves,
  }) {
    // Threshold-only classification is cheap and common in injected tests or
    // engines without MultiPV. The sacrifice heuristic is the expensive part.
    if (!scores.any((score) => score.lines.length > 1)) {
      return Future.value(
        classify(scores: scores, positions: positions, uciMoves: uciMoves),
      );
    }
    return Isolate.run(
      () => classify(scores: scores, positions: positions, uciMoves: uciMoves),
    );
  }

  static List<ClassifiedMove> classify({
    required List<StockfishReview> scores,
    required List<String> positions,
    required List<String> uciMoves,
  }) {
    final count = min(
      uciMoves.length,
      min(max(0, scores.length - 1), max(0, positions.length - 1)),
    );
    final result = <ClassifiedMove>[];
    final materialEvaluator = _NaiveMaterialEvaluator(
      nodeLimit: _captureSearchNodeLimit,
    );
    for (var ply = 1; ply <= count; ply++) {
      final whiteMoved = positions[ply - 1].split(' ')[1] == 'w';
      final previous = _normalized(scores[ply - 1], whiteMoved);
      final next = _normalized(scores[ply], whiteMoved);
      final loss = _winChance(previous) - _winChance(next);
      MoveClassification? classification;
      if (loss > 20) {
        classification = MoveClassification.blunder;
      } else if (loss > 10) {
        classification = MoveClassification.mistake;
      } else if (loss > 5) {
        classification = MoveClassification.dubious;
      } else {
        final previousReview = scores[ply - 1];
        final lines = previousReview.lines;
        if (lines.length > 1 &&
            lines[0].moves.isNotEmpty &&
            lines[1].moves.isNotEmpty) {
          final best = _normalizedLine(lines[0], whiteMoved);
          final second = _normalizedLine(lines[1], whiteMoved);
          final isSacrifice = _isSacrifice(
            positions[ply - 1],
            positions[ply],
            materialEvaluator,
          );
          if (_winChance(best) - _winChance(second) > 10 &&
              uciMoves[ply - 1] == lines[0].moves.first) {
            if (isSacrifice) {
              classification = MoveClassification.brilliant;
            } else {
              final beforePrevious = ply > 1
                  ? _normalized(scores[ply - 2], whiteMoved)
                  : 0;
              if (_winChance(best) - _winChance(beforePrevious) > 5) {
                classification = MoveClassification.good;
              }
            }
          } else if (isSacrifice && next > -200) {
            classification = MoveClassification.interesting;
          }
        }
      }
      if (classification != null) {
        result.add(
          ClassifiedMove(
            ply: ply,
            classification: classification,
            moverIsWhite: whiteMoved,
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  static int _normalized(StockfishReview review, bool whiteMoved) {
    final value = review.mate == null
        ? review.evaluation.clamp(-1000, 1000)
        : 1000 * review.mate!.sign;
    return whiteMoved ? value : -value;
  }

  static int _normalizedLine(StockfishLine line, bool whiteMoved) {
    final value = line.mate == null
        ? line.evaluation.clamp(-1000, 1000)
        : 1000 * line.mate!.sign;
    return whiteMoved ? value : -value;
  }

  static double _winChance(int centipawns) =>
      50 + 50 * (2 / (1 + exp(-0.00368208 * centipawns)) - 1);

  static bool _isSacrifice(
    String beforeFen,
    String afterFen,
    _NaiveMaterialEvaluator evaluator,
  ) {
    final before = evaluator.evaluate(beforeFen);
    final after = -evaluator.evaluate(afterFen);
    return before > after + 100;
  }

  static int _materialForTurn(String fen) {
    const values = {'p': 90, 'n': 300, 'b': 300, 'r': 500, 'q': 1000};
    var white = 0;
    var black = 0;
    for (final rune in fen.split(' ').first.runes) {
      final piece = String.fromCharCode(rune);
      final value = values[piece.toLowerCase()] ?? 0;
      if (piece == piece.toUpperCase()) {
        white += value;
      } else {
        black += value;
      }
    }
    final score = white - black;
    return fen.split(' ')[1] == 'w' ? score : -score;
  }

  static int _pieceValue(chess.PieceType piece) => switch (piece.name) {
    'p' => 90,
    'n' || 'b' => 300,
    'r' => 500,
    'q' => 1000,
    _ => 0,
  };
}

class _NaiveMaterialEvaluator {
  _NaiveMaterialEvaluator({required this.nodeLimit});

  final int nodeLimit;
  final Map<String, int> _cache = {};

  int evaluate(String fen) => _cache.putIfAbsent(fen, () {
    final position = chess.Chess.fromFEN(fen);
    final moves = position
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .toList(growable: false);
    if (moves.isEmpty) return position.in_checkmate ? -10000 : 0;
    final budget = _CaptureSearchBudget(nodeLimit);
    var best = -10000;
    for (final move in moves) {
      final next = chess.Chess.fromFEN(position.fen)..move(move);
      best = max(best, -_captureSearch(next, -10000, 10000, budget));
      if (budget.exhausted) break;
    }
    return best;
  });

  int _captureSearch(
    chess.Chess position,
    int alpha,
    int beta,
    _CaptureSearchBudget budget,
  ) {
    var lower = alpha;
    final standPat = MoveClassifier._materialForTurn(position.fen);
    if (!budget.takeNode()) return standPat;
    if (standPat >= beta) return beta;
    lower = max(lower, standPat);
    final captures =
        position
            .moves({'asObjects': true})
            .cast<chess.Move>()
            .where((move) => move.captured != null)
            .toList(growable: false)
          ..sort(
            (a, b) =>
                MoveClassifier._pieceValue(b.captured!)
                    .compareTo(MoveClassifier._pieceValue(a.captured!)),
          );
    for (final capture in captures) {
      final next = chess.Chess.fromFEN(position.fen)..move(capture);
      final value = -_captureSearch(next, -beta, -lower, budget);
      if (value >= beta) return beta;
      lower = max(lower, value);
      if (budget.exhausted) break;
    }
    return lower;
  }
}

class _CaptureSearchBudget {
  _CaptureSearchBudget(this.remaining);

  int remaining;
  bool get exhausted => remaining <= 0;

  bool takeNode() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}

class MoveClassificationSummary extends StatelessWidget {
  const MoveClassificationSummary({
    required this.moves,
    required this.selectedPly,
    required this.onSelected,
    super.key,
  });

  final List<ClassifiedMove> moves;
  final int selectedPly;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget countButton(
      List<ClassifiedMove> matches,
      String side,
      MoveClassification classification,
    ) {
      final selected = matches.any((move) => move.ply == selectedPly);
      final next =
          matches.where((move) => move.ply > selectedPly).firstOrNull ??
          matches.firstOrNull;
      final label = '${matches.length} $side ${classification.label} moves';
      return SizedBox(
        width: 48,
        height: 48,
        child: Semantics(
          button: matches.isNotEmpty,
          selected: selected,
          label: label,
          hint: matches.isEmpty ? null : 'Go to next',
          child: Tooltip(
            message: matches.isEmpty ? label : '$label · tap for next',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: next == null ? null : () => onSelected(next.ply),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? classification.color.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(child: Text('${matches.length}')),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      key: const ValueKey('move-classification-summary'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            const Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text('W', textAlign: TextAlign.center),
                ),
                Expanded(child: SizedBox.shrink()),
                SizedBox(
                  width: 48,
                  child: Text('B', textAlign: TextAlign.center),
                ),
              ],
            ),
            for (final classification in MoveClassification.values)
              Builder(
                builder: (context) {
                  final white = moves
                      .where(
                        (move) =>
                            move.whiteMoved &&
                            move.classification == classification,
                      )
                      .toList(growable: false);
                  final black = moves
                      .where(
                        (move) =>
                            !move.whiteMoved &&
                            move.classification == classification,
                      )
                      .toList(growable: false);
                  return DefaultTextStyle.merge(
                    style: TextStyle(color: classification.color),
                    child: Row(
                      children: [
                        countButton(white, 'White', classification),
                        SizedBox(
                          width: 42,
                          child: Text(
                            classification.symbol,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            classification.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        countButton(black, 'Black', classification),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class GamePhases {
  const GamePhases({this.middlegamePly, this.endgamePly});

  final int? middlegamePly;
  final int? endgamePly;
}

class GamePhaseDetector {
  static GamePhases detect(List<String> positions) {
    int? middlegame;
    int? endgame;
    for (var ply = 0; ply < positions.length; ply++) {
      final board = _pieces(positions[ply]);
      final majorMinorCount = board
          .where((piece) => 'qrbn'.contains(piece.piece.toLowerCase()))
          .length;
      if (middlegame == null &&
          (majorMinorCount <= 10 ||
              _backrankSparse(board) ||
              _mixedness(board) > 150)) {
        middlegame = ply;
      }
      if (middlegame != null && endgame == null && majorMinorCount <= 6) {
        endgame = ply;
      }
    }
    return GamePhases(middlegamePly: middlegame, endgamePly: endgame);
  }

  static List<({String piece, int file, int rank})> _pieces(String fen) {
    final result = <({String piece, int file, int rank})>[];
    final ranks = fen.split(' ').first.split('/');
    for (var row = 0; row < ranks.length; row++) {
      var file = 0;
      for (final rune in ranks[row].runes) {
        final value = String.fromCharCode(rune);
        final empty = int.tryParse(value);
        if (empty != null) {
          file += empty;
        } else {
          result.add((piece: value, file: file, rank: 7 - row));
          file++;
        }
      }
    }
    return result;
  }

  static bool _backrankSparse(
    List<({String piece, int file, int rank})> board,
  ) {
    final white = board
        .where(
          (piece) =>
              piece.rank == 0 && piece.piece == piece.piece.toUpperCase(),
        )
        .length;
    final black = board
        .where(
          (piece) =>
              piece.rank == 7 && piece.piece == piece.piece.toLowerCase(),
        )
        .length;
    return white < 4 || black < 4;
  }

  static int _mixedness(List<({String piece, int file, int rank})> board) {
    var total = 0;
    for (var y = 0; y <= 6; y++) {
      for (var x = 0; x <= 6; x++) {
        final region = board.where(
          (piece) =>
              piece.file >= x &&
              piece.file <= x + 1 &&
              piece.rank >= y &&
              piece.rank <= y + 1,
        );
        final white = region
            .where((piece) => piece.piece == piece.piece.toUpperCase())
            .length;
        final black = region.length - white;
        total += _regionScore(y + 1, white, black);
      }
    }
    return total;
  }

  static int _regionScore(int y, int white, int black) {
    if (white == 0 && black == 0) return 0;
    if (white == 1 && black == 0) return 1 + (8 - y);
    if (white == 2 && black == 0) return y > 2 ? 2 + (y - 2) : 0;
    if (white == 3 && black == 0) return y > 1 ? 3 + (y - 1) : 0;
    if (white == 4 && black == 0) return y > 1 ? 3 + (y - 1) : 0;
    if (white == 0 && black == 1) return 1 + y;
    if (white == 1 && black == 1) return 5 + (4 - y).abs();
    if (white == 2 && black == 1) return 4 + (y - 1);
    if (white == 3 && black == 1) return 5 + (y - 1);
    if (white == 0 && black == 2) return y < 6 ? 2 + (6 - y) : 0;
    if (white == 1 && black == 2) return 4 + (7 - y);
    if (white == 2 && black == 2) return 7;
    if (white == 0 && black == 3) return y < 7 ? 3 + (7 - y) : 0;
    if (white == 1 && black == 3) return 5 + (7 - y);
    if (white == 0 && black == 4) return y < 7 ? 3 + (7 - y) : 0;
    return 0;
  }
}

class ReviewBoardOverlayPainter extends CustomPainter {
  const ReviewBoardOverlayPainter({
    required this.orientation,
    this.agreementUci,
    this.agreementTailColor,
    this.annotationSquare,
    this.classification,
  });

  final dc.Side orientation;
  final String? agreementUci;
  final Color? agreementTailColor;
  final String? annotationSquare;
  final MoveClassification? classification;

  Offset _squareCenter(String square, double squareSize) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square[1]) - 1;
    final x = orientation == dc.Side.white ? file : 7 - file;
    final y = orientation == dc.Side.white ? 7 - rank : rank;
    return Offset((x + 0.5) * squareSize, (y + 0.5) * squareSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    final agreement = agreementUci;
    if (agreement != null && agreement.length >= 4) {
      final from = _squareCenter(agreement.substring(0, 2), squareSize);
      final to = _squareCenter(agreement.substring(2, 4), squareSize);
      final angle = atan2(to.dy - from.dy, to.dx - from.dx);
      final start = from + Offset(cos(angle), sin(angle)) * (squareSize / 3);
      final arrowSize = squareSize * 0.48;
      const arrowAngle = pi / 5;
      final arrowHeight = arrowSize * sin((pi - arrowAngle * 2) / 2);
      final headOffset = Offset(cos(angle), sin(angle)) * arrowHeight;
      canvas.drawLine(
        start,
        to - headOffset,
        Paint()
          ..color = agreementTailColor ?? const Color(0xff3d9be9)
          ..strokeWidth = squareSize / 4
          ..strokeCap = StrokeCap.butt,
      );
      final head = Path()
        ..moveTo(
          to.dx - arrowSize * cos(angle - arrowAngle),
          to.dy - arrowSize * sin(angle - arrowAngle),
        )
        ..lineTo(to.dx, to.dy)
        ..lineTo(
          to.dx - arrowSize * cos(angle + arrowAngle),
          to.dy - arrowSize * sin(angle + arrowAngle),
        )
        ..close();
      canvas.drawPath(head, Paint()..color = const Color(0xffe89b3c));
    }

    final square = annotationSquare;
    final moveClass = classification;
    if (square == null || moveClass == null) return;
    final center = _squareCenter(square, squareSize);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: squareSize, height: squareSize),
      Paint()..color = moveClass.color.withValues(alpha: 0.22),
    );
    final badgeCenter = center + Offset(squareSize * 0.34, -squareSize * 0.34);
    canvas.drawCircle(
      badgeCenter + const Offset(0, 1),
      squareSize * 0.24,
      Paint()..color = Colors.black38,
    );
    canvas.drawCircle(
      badgeCenter,
      squareSize * 0.23,
      Paint()..color = moveClass.color,
    );
    final text = TextPainter(
      text: TextSpan(
        text: moveClass.symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: squareSize * (moveClass.symbol.length > 1 ? 0.25 : 0.32),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, badgeCenter - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant ReviewBoardOverlayPainter oldDelegate) =>
      oldDelegate.orientation != orientation ||
      oldDelegate.agreementUci != agreementUci ||
      oldDelegate.agreementTailColor != agreementTailColor ||
      oldDelegate.annotationSquare != annotationSquare ||
      oldDelegate.classification != classification;
}

class GameAccuracy {
  const GameAccuracy({required this.white, required this.black});

  final double? white;
  final double? black;

  static GameAccuracy fromScores(
    List<StockfishReview> scores, {
    bool startsWithWhite = true,
  }) {
    if (scores.length < 2) {
      return const GameAccuracy(white: null, black: null);
    }
    final winPercents = scores.map((score) => score.whiteWinPercent).toList();
    final windowSize = (scores.length ~/ 10).clamp(2, 8);
    final windows = <List<double>>[
      ...List.generate(
        min(windowSize, winPercents.length) - 2,
        (_) => winPercents.take(windowSize).toList(),
      ),
      for (var start = 0; start + windowSize <= winPercents.length; start++)
        winPercents.sublist(start, start + windowSize),
    ];
    final whiteMoves = <(double, double)>[];
    final blackMoves = <(double, double)>[];
    for (var ply = 0; ply + 1 < scores.length; ply++) {
      final whiteMoved = ply.isEven == startsWithWhite;
      final beforeWhite = winPercents[ply];
      final afterWhite = winPercents[ply + 1];
      final before = whiteMoved ? beforeWhite : 100 - beforeWhite;
      final after = whiteMoved ? afterWhite : 100 - afterWhite;
      final accuracy = moveAccuracy(before, after);
      final weight = _standardDeviation(windows[ply]).clamp(0.5, 12.0);
      (whiteMoved ? whiteMoves : blackMoves).add((accuracy, weight));
    }
    return GameAccuracy(
      white: _gameMean(whiteMoves),
      black: _gameMean(blackMoves),
    );
  }

  static double moveAccuracy(double before, double after) {
    if (after >= before) return 100;
    final loss = before - after;
    return (103.1668100711649 * exp(-0.04354415386753951 * loss) -
            3.166924740191411 +
            1)
        .clamp(0, 100)
        .toDouble();
  }

  static double _standardDeviation(List<double> values) {
    final mean = values.reduce((total, value) => total + value) / values.length;
    final variance =
        values
            .map((value) => pow(value - mean, 2))
            .reduce((total, value) => total + value) /
        values.length;
    return sqrt(variance);
  }

  static double? _gameMean(List<(double, double)> moves) {
    if (moves.isEmpty) return null;
    final totalWeight = moves.fold<double>(0, (total, move) => total + move.$2);
    final weighted =
        moves.fold<double>(0, (total, move) => total + move.$1 * move.$2) /
        totalWeight;
    final harmonic = moves.any((move) => move.$1 == 0)
        ? 0.0
        : moves.length /
              moves.fold<double>(0, (total, move) => total + 1 / move.$1);
    return (weighted + harmonic) / 2;
  }
}

class AccuracySummary extends StatelessWidget {
  const AccuracySummary({
    required this.scores,
    this.startsWithWhite = true,
    super.key,
  });

  final bool startsWithWhite;

  final List<StockfishReview> scores;

  @override
  Widget build(BuildContext context) {
    final accuracy = GameAccuracy.fromScores(
      scores,
      startsWithWhite: startsWithWhite,
    );
    String label(double? value) => value == null
        ? 'Not enough moves'
        : '${value.clamp(0, 100).toStringAsFixed(1)}%';
    Widget playerAccuracy(String side, double? value) => Expanded(
      child: Column(
        children: [
          Text(side, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            label(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return Semantics(
      label: 'Game accuracy',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Accuracy',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        playerAccuracy('White', accuracy.white),
                        const SizedBox(width: 12),
                        playerAccuracy('Black', accuracy.black),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisGraph extends StatelessWidget {
  const AnalysisGraph({
    required this.scores,
    required this.positions,
    required this.classifications,
    required this.selectedPly,
    required this.onSelected,
    super.key,
  });

  final List<StockfishReview> scores;
  final List<String> positions;
  final List<ClassifiedMove> classifications;
  final int selectedPly;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = scores[selectedPly.clamp(0, scores.length - 1)];
    final scoreLabel = selected.mate == null
        ? '${selected.evaluation >= 0 ? '+' : ''}${(selected.evaluation / 100).toStringAsFixed(1)}'
        : '#${selected.mate}';
    final boundedPly = selectedPly.clamp(0, scores.length - 1);
    return Semantics(
      label: 'Computer analysis graph',
      value: 'Position $boundedPly of ${scores.length - 1}, $scoreLabel',
      increasedValue: boundedPly < scores.length - 1
          ? 'Position ${boundedPly + 1}'
          : null,
      decreasedValue: boundedPly > 0 ? 'Position ${boundedPly - 1}' : null,
      onIncrease: boundedPly < scores.length - 1
          ? () => onSelected(boundedPly + 1)
          : null,
      onDecrease: boundedPly > 0 ? () => onSelected(boundedPly - 1) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Position $boundedPly of ${scores.length - 1}  ·  $scoreLabel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (scores.length < 2) return;
                  final fraction =
                      (details.localPosition.dx / constraints.maxWidth).clamp(
                        0.0,
                        1.0,
                      );
                  onSelected((fraction * (scores.length - 1)).round());
                },
                child: CustomPaint(
                  painter: AnalysisGraphPainter(
                    scores: scores,
                    positions: positions,
                    classifications: classifications,
                    selectedPly: selectedPly,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisGraphPainter extends CustomPainter {
  AnalysisGraphPainter({
    required this.scores,
    this.positions = const [],
    this.classifications = const [],
    required this.selectedPly,
  });

  final List<StockfishReview> scores;
  final List<String> positions;
  final List<ClassifiedMove> classifications;
  final int selectedPly;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.save();
    canvas.clipRRect(bounds);
    final background = Paint()..color = const Color(0xff262421);
    canvas.drawRRect(bounds, background);
    if (scores.isEmpty) {
      canvas.restore();
      return;
    }
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final normalized = scores[i].whiteWinningChances;
      final x = scores.length == 1 ? 0.0 : i * size.width / (scores.length - 1);
      final y = size.height / 2 - normalized * (size.height / 2 - 8);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final whiteArea = Path()
      ..moveTo(0, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      whiteArea.lineTo(point.dx, point.dy);
    }
    whiteArea
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      whiteArea,
      Paint()
        ..color = const Color(0xffeeeeee)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 1,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xff3d9be9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final phases = GamePhaseDetector.detect(positions);
    void phaseLine(int ply, String label) {
      if (scores.length < 2 || ply <= 0 || ply >= scores.length) return;
      final x = ply * size.width / (scores.length - 1);
      final paint = Paint()
        ..color = const Color(0xffa0a0a0)
        ..strokeWidth = 1;
      for (var y = 0.0; y < size.height; y += 8) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, min(y + 4, size.height)),
          paint,
        );
      }
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xffd0d0d0),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: max(0.0, size.width - x - 4));
      text.paint(canvas, Offset(min(x + 4, size.width - text.width), 4));
    }

    final initialPhase = phases.endgamePly == 0
        ? 'Endgame'
        : phases.middlegamePly == 0
        ? 'Middlegame'
        : 'Opening';
    final opening = TextPainter(
      text: TextSpan(
        text: initialPhase,
        style: const TextStyle(
          color: Color(0xffd0d0d0),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    opening.paint(canvas, const Offset(5, 4));
    if (phases.middlegamePly != null) {
      phaseLine(phases.middlegamePly!, 'Middlegame');
    }
    if (phases.endgamePly != null) {
      phaseLine(phases.endgamePly!, 'Endgame');
    }
    for (final move in classifications) {
      if (move.ply < 0 || move.ply >= points.length) continue;
      canvas.drawCircle(
        points[move.ply],
        4,
        Paint()
          ..color = move.classification.color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        points[move.ply],
        4,
        Paint()
          ..color = const Color(0xffeeeeee)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
    final boundedSelectedPly = selectedPly.clamp(0, scores.length - 1);
    final selectedX = scores.length == 1
        ? 0.0
        : boundedSelectedPly * size.width / (scores.length - 1);
    canvas.drawLine(
      Offset(selectedX, 0),
      Offset(selectedX, size.height),
      Paint()
        ..color = const Color(0xffe6a23c)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnalysisGraphPainter oldDelegate) =>
      oldDelegate.selectedPly != selectedPly ||
      oldDelegate.scores != scores ||
      oldDelegate.positions != positions ||
      oldDelegate.classifications != classifications;
}

class EvaluationBar extends StatelessWidget {
  const EvaluationBar({
    required this.evaluation,
    this.mate,
    this.enabled = true,
    super.key,
  });

  final int? evaluation;
  final int? mate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final score = enabled ? evaluation : null;
    final whiteShare = mate != null
        ? (1 +
                  StockfishReview(
                    score ?? 0,
                    '',
                    mate: mate,
                  ).whiteWinningChances) /
              2
        : score == null
        ? 0.5
        : (1 + StockfishReview(score, '').whiteWinningChances) / 2;
    return SizedBox(
      width: max(24.0, MediaQuery.textScalerOf(context).scale(24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final whiteHeight = constraints.maxHeight * whiteShare;
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: enabled
                      ? const Color(0xff262421)
                      : const Color(0xff4a4d4b),
                ),
              ),
              if (enabled)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: whiteHeight,
                  child: const ColoredBox(color: Color(0xfff0f0f0)),
                ),
              if (enabled && (score != null || mate != null))
                Align(
                  alignment: (mate ?? score!) < 0
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _scoreLabel(score, mate),
                        maxLines: 1,
                        style: TextStyle(
                          color: (mate ?? score!) < 0
                              ? Colors.white
                              : Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _scoreLabel(int? score, int? mate) {
    if (mate != null) return '#$mate';
    if (score == null) return '';
    final pawns = score / 100;
    return '${pawns >= 0 ? '+' : ''}${pawns.toStringAsFixed(1)}';
  }
}

class MaterialDifferenceSide {
  const MaterialDifferenceSide({required this.pieces, required this.score});

  final Map<String, int> pieces;
  final int score;
}

class MaterialDifferenceData {
  const MaterialDifferenceData({required this.white, required this.black});

  factory MaterialDifferenceData.fromFen(String fen) {
    final whiteCount = <String, int>{};
    final blackCount = <String, int>{};
    for (final rune in fen.split(' ').first.runes) {
      final piece = String.fromCharCode(rune);
      if (!'prnbqPRNBQ'.contains(piece)) continue;
      final target = piece == piece.toUpperCase() ? whiteCount : blackCount;
      final role = piece.toLowerCase();
      target[role] = (target[role] ?? 0) + 1;
    }
    const values = {'p': 1, 'n': 3, 'b': 3, 'r': 5, 'q': 9};
    final whitePieces = <String, int>{};
    final blackPieces = <String, int>{};
    var whiteScore = 0;
    for (final role in values.keys) {
      final difference = (whiteCount[role] ?? 0) - (blackCount[role] ?? 0);
      whiteScore += values[role]! * difference;
      if (difference > 0) {
        whitePieces[role] = difference;
      } else if (difference < 0) {
        blackPieces[role] = -difference;
      }
    }
    return MaterialDifferenceData(
      white: MaterialDifferenceSide(
        pieces: Map.unmodifiable(whitePieces),
        score: whiteScore,
      ),
      black: MaterialDifferenceSide(
        pieces: Map.unmodifiable(blackPieces),
        score: -whiteScore,
      ),
    );
  }

  final MaterialDifferenceSide white;
  final MaterialDifferenceSide black;

  MaterialDifferenceSide byColor(chess.Color color) =>
      color == chess.Color.WHITE ? white : black;
}

class MaterialDifference extends StatelessWidget {
  const MaterialDifference({required this.fen, required this.side, super.key});

  final String fen;
  final chess.Color side;

  // These are the exact private-use glyphs used by Lichess Mobile's
  // MaterialDifferenceDisplay with its bundled LichessIcons font.
  static const _icons = {
    'b': IconData(0xf43a, fontFamily: 'LichessIcons'),
    'n': IconData(0xf441, fontFamily: 'LichessIcons'),
    'p': IconData(0xf443, fontFamily: 'LichessIcons'),
    'q': IconData(0xf445, fontFamily: 'LichessIcons'),
    'r': IconData(0xf447, fontFamily: 'LichessIcons'),
  };
  static const _names = {
    'q': 'queen',
    'r': 'rook',
    'b': 'bishop',
    'n': 'knight',
    'p': 'pawn',
  };
  // Match dartchess Role.values as used by Lichess Mobile: low-value pieces
  // first, then queen (king is omitted because it cannot be a material extra).
  static const _order = ['p', 'n', 'b', 'r', 'q'];

  @override
  Widget build(BuildContext context) {
    final difference = MaterialDifferenceData.fromFen(fen).byColor(side);
    final pieces = <Icon>[];
    final spoken = <String>[];
    final size = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final remainingHeight =
        size.height - viewPadding.vertical - size.width - kToolbarHeight - 56;
    final isShortScreen = remainingHeight < 200;
    final iconSize = isShortScreen ? 11.0 : 13.0;
    final textSize = isShortScreen ? 12.0 : 14.0;
    final shade =
        DefaultTextStyle.of(context).style.color?.withValues(alpha: 0.5) ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    for (final role in _order) {
      final count = difference.pieces[role] ?? 0;
      pieces.addAll(
        List.generate(
          count,
          (_) => Icon(_icons[role], size: iconSize, color: shade),
        ),
      );
      if (count > 0) {
        spoken.add('$count ${_names[role]}${count == 1 ? '' : 's'}');
      }
    }
    final sideName = side == chess.Color.WHITE ? 'White' : 'Black';
    final score = difference.score > 0 ? '+${difference.score}' : '';
    final description = [
      if (spoken.isNotEmpty) spoken.join(', '),
      if (score.isNotEmpty) '$score material advantage',
    ].join(', ');
    return Semantics(
      key: ValueKey(
        side == chess.Color.WHITE ? 'white-material' : 'black-material',
      ),
      label: '$sideName material${description.isEmpty ? '' : ': $description'}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...pieces,
            const SizedBox(width: 3),
            Text(
              score,
              style: TextStyle(color: shade, fontSize: textSize),
            ),
          ],
        ),
      ),
    );
  }
}
