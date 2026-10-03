import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stockfish_failure_test.dart' show FakeStockfish;

StockfishReview score(
  GameAnalysisQuality quality,
  String fen,
  int cp, {
  String? move,
}) {
  final roots = chess.Chess.fromFEN(fen)
      .moves({'asObjects': true})
      .cast<chess.Move>()
      .map(MaiaEncoding.uci)
      .toList();
  final best = move ?? roots.first;
  final second = roots.firstWhere((r) => r != best);
  final white = fen.split(' ')[1] == 'w';
  return StockfishReview(
    cp,
    best,
    lines: [
      StockfishLine(evaluation: cp, moves: [best]),
      StockfishLine(evaluation: cp + (white ? -300 : 300), moves: [second]),
    ],
    evidence: StockfishSearchEvidence(
      depth: quality.depth,
      nodes: 100,
      timeMs: 100,
      complete: true,
      reset: true,
      quality: quality,
    ),
  );
}

class WindowEngine extends FakeStockfish {
  WindowEngine(this.scores);
  final Map<String, StockfishReview> scores;
  final commands = <String>[];
  String fen = '';
  int searches = 0;
  int? failAt;
  void Function(int)? onSearch;
  @override
  set stdin(String command) {
    commands.add(command);
    if (command.startsWith('position fen ')) fen = command.substring(13);
    if (command.startsWith('go ')) {
      searches++;
      onSearch?.call(searches);
      if (searches == failAt) throw StateError('window failure');
      final review = scores[fen]!;
      final sign = fen.split(' ')[1] == 'w' ? 1 : -1;
      final depth = command.split(' ')[2];
      searchOutput = [
        for (var i = 0; i < review.lines.length; i++)
          'info depth $depth multipv ${i + 1} score cp ${review.lines[i].evaluation * sign} pv ${review.lines[i].moves.join(' ')}',
        'bestmove ${review.bestMove}',
      ];
    }
    super.stdin = command;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final quality in GameAnalysisQuality.values) {
    for (final failure in [0, 1, 2, 3]) {
      test(
        '${quality.name}: Good verifies entire three-position window, failure=$failure',
        () async {
          final game = chess.Chess();
          final positions = [
            game.fen,
            (game..move('e4')).fen,
            (game..move('e5')).fen,
          ];
          final scores = [
            score(quality, positions[0], 0, move: 'e2e4'),
            score(quality, positions[1], -300, move: 'e7e5'),
            score(quality, positions[2], -300),
          ];
          final engine = WindowEngine(Map.fromIterables(positions, scores))
            ..failAt = failure;
          final analyzer = StockfishAnalyzer.withFactory(engine.create);
          try {
            final result = await analyzer.confirmAnnotations(
              quality: quality,
              scores: scores,
              positions: positions,
              uciMoves: ['e2e4', 'e7e5'],
              classifiedMoves: const [
                ClassifiedMove(ply: 2, classification: MoveClassification.good),
              ],
              scope: MaiaInferenceScope(),
              isCurrent: () => true,
            );
            expect(result.map((s) => s.evaluation), [0, -300, -300]);
            expect(result[0], same(scores[0]));
            expect(result[2], same(scores[2]));
            if (failure == 0) {
              expect(
                engine.commands.where((c) => c.startsWith('position fen ')),
                positions.map((p) => 'position fen $p'),
              );
              final evidence = result[1].annotationConfirmation!;
              expect(evidence.beforePrevious!.evaluation, 0);
              expect(evidence.before.evaluation, -300);
              expect(evidence.after.evaluation, -300);
              expect(
                MoveClassifier.classify(
                  scores: result,
                  positions: positions,
                  uciMoves: ['e2e4', 'e7e5'],
                ).where((m) => m.ply == 2).single.classification,
                MoveClassification.good,
              );
            } else {
              expect(result, scores);
              expect(engine.searches, failure);
            }
          } finally {
            await analyzer.close();
            await engine.output.close();
          }
        },
      );
    }
    test(
      '${quality.name}: actual scope cancellation cannot attach a partial Good window',
      () async {
        final game = chess.Chess();
        final positions = [
          game.fen,
          (game..move('e4')).fen,
          (game..move('e5')).fen,
        ];
        final scores = [
          score(quality, positions[0], 0),
          score(quality, positions[1], -300, move: 'e7e5'),
          score(quality, positions[2], -300),
        ];
        final engine = WindowEngine(Map.fromIterables(positions, scores));
        final analyzer = StockfishAnalyzer.withFactory(engine.create);
        final scope = MaiaInferenceScope();
        engine.onSearch = (count) {
          if (count == 2) analyzer.cancel(scope);
        };
        try {
          final result = await analyzer.confirmAnnotations(
            quality: quality,
            scores: scores,
            positions: positions,
            uciMoves: ['e2e4', 'e7e5'],
            classifiedMoves: const [
              ClassifiedMove(ply: 2, classification: MoveClassification.good),
            ],
            scope: scope,
            isCurrent: () => true,
          );
          expect(result, scores);
          expect(engine.searches, 2);
          expect(
            await AppDiagnostics.report(),
            isNot(contains('[stockfish-annotation-check]')),
          );
        } finally {
          await analyzer.close();
          await engine.output.close();
        }
      },
    );
  }
  test('six-search budget excludes ordinary labels and fits mixed two/three-score windows', () {
    final game = chess.Chess();
    final positions = [game.fen];
    for (final move in ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'Ba4', 'Nf6']) {
      game.move(move);
      positions.add(game.fen);
    }
    final moves = [
      'e2e4',
      'e7e5',
      'g1f3',
      'b8c6',
      'f1b5',
      'a7a6',
      'b5a4',
      'g8f6',
    ];
    final scores = [
      for (final fen in positions)
        score(GameAnalysisQuality.thorough, fen, 300),
    ];
    final candidates = MoveClassifier.confirmationPlies(
      scores: scores,
      positions: positions,
      uciMoves: moves,
      classifiedMoves: const [
        ClassifiedMove(ply: 1, classification: MoveClassification.interesting),
        ClassifiedMove(ply: 2, classification: MoveClassification.good),
        ClassifiedMove(ply: 3, classification: MoveClassification.brilliant),
        ClassifiedMove(ply: 4, classification: MoveClassification.good),
        ClassifiedMove(ply: 5, classification: MoveClassification.brilliant),
      ],
    );
    expect(candidates, [2, 3]); // 3 + 2 searches, no remaining window fits.
    expect(
      MoveClassifier.confirmationPlies(
        scores: scores,
        positions: positions,
        uciMoves: moves,
        classifiedMoves: [
          for (var ply = 1; ply <= 8; ply++)
            ClassifiedMove(
              ply: ply,
              classification: MoveClassification.brilliant,
            ),
        ],
      ),
      [1, 2, 3],
    );
  });
}
