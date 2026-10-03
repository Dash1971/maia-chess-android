import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stockfish_failure_test.dart' show FakeStockfish;

const before =
    'r2q1rk1/pp2ppbp/2p2np1/2Q3B1/n2PP1b1/2N2N2/PP3PPP/3RKB1R w K - 7 12';
const after =
    'r2q1rk1/pp2ppbp/2p2np1/6B1/n2PP1b1/Q1N2N2/PP3PPP/3RKB1R b K - 8 12';

StockfishReview review(GameAnalysisQuality quality, {bool successor = false}) =>
    StockfishReview(
      300,
      successor ? 'a4c3' : 'c5a3',
      lines: successor
          ? const [
              StockfishLine(evaluation: 300, moves: ['a4c3']),
              StockfishLine(evaluation: 400, moves: ['b7b5']),
            ]
          : const [
              StockfishLine(evaluation: 300, moves: ['c5a3']),
              StockfishLine(evaluation: -10, moves: ['c5b4']),
            ],
      evidence: StockfishSearchEvidence(
        depth: quality.depth,
        nodes: 100,
        timeMs: 20,
        complete: true,
        reset: true,
        quality: quality,
        previousLines: successor
            ? const [
                StockfishLine(evaluation: 300, moves: ['a4c3']),
                StockfishLine(evaluation: 400, moves: ['b7b5']),
              ]
            : const [
                StockfishLine(evaluation: 0, moves: ['c5a3']),
                StockfishLine(evaluation: -10, moves: ['c5b4']),
              ],
      ),
    );
final unstable = review(GameAnalysisQuality.fast);
final next = review(GameAnalysisQuality.fast, successor: true);
const brilliant = [
  ClassifiedMove(ply: 1, classification: MoveClassification.brilliant),
];

class ConfirmationEngine extends FakeStockfish {
  final commands = <String>[];
  int searches = 0;
  int? failAt;
  int? forcedDepth;
  void Function(int)? onSearch;
  @override
  set stdin(String command) {
    commands.add(command);
    if (command.startsWith('go ')) {
      searches++;
      onSearch?.call(searches);
      if (searches == failAt) throw StateError('test failure');
      final depth = forcedDepth ?? int.parse(command.split(' ')[2]);
      // Independent search refutes the alleged Qa3 advantage.
      searchOutput = searches.isOdd
          ? [
              'info depth $depth multipv 1 score cp -190 pv c5a3',
              'info depth $depth multipv 2 score cp -200 pv c5b4',
              'bestmove c5a3',
            ]
          : [
              'info depth $depth multipv 1 score cp 190 pv a4c3',
              'info depth $depth multipv 2 score cp 10 pv b7b5',
              'bestmove a4c3',
            ];
    }
    super.stdin = command;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final quality in GameAnalysisQuality.values) {
    test(
      '${quality.name}: confirmation uses selected budget, preserves baseline and rejects refuted award',
      () async {
        final engine = ConfirmationEngine();
        final analyzer = StockfishAnalyzer.withFactory(engine.create);
        final original = [review(quality), review(quality, successor: true)];
        try {
          final checked = await analyzer.confirmAnnotations(
            quality: quality,
            scores: original,
            positions: [before, after],
            uciMoves: ['c5a3'],
            classifiedMoves: brilliant,
            scope: MaiaInferenceScope(),
            isCurrent: () => true,
          );
          expect(engine.commands.where((c) => c.startsWith('go ')), [
            'go depth ${quality.depth + 2} movetime ${quality.moveTimeMs}',
            'go depth ${quality.depth + 2} movetime ${quality.moveTimeMs}',
          ]);
          expect(engine.commands.where((c) => c == 'ucinewgame').length, 1);
          expect(checked.map((s) => s.evaluation), [300, 300]);
          expect(checked[0].lines, same(original[0].lines));
          expect(checked[1], same(original[1]));
          expect(checked[0].annotationConfirmation!.before.evaluation, -190);
          expect(checked[0].annotationConfirmation!.after.evaluation, -190);
          expect(original[0].annotationConfirmation, isNull);
          expect(
            MoveClassifier.classify(
              scores: checked,
              positions: [before, after],
              uciMoves: ['c5a3'],
            ),
            isEmpty,
          );
        } finally {
          await analyzer.close();
          await engine.output.close();
        }
      },
    );
    test(
      '${quality.name}: shallower complete verification cannot validate a deeper source',
      () async {
        final engine = ConfirmationEngine()..forcedDepth = quality.depth - 1;
        final analyzer = StockfishAnalyzer.withFactory(engine.create);
        final original = [review(quality), review(quality, successor: true)];
        try {
          final checked = await analyzer.confirmAnnotations(
            quality: quality,
            scores: original,
            positions: [before, after],
            uciMoves: ['c5a3'],
            classifiedMoves: brilliant,
            scope: MaiaInferenceScope(),
            isCurrent: () => true,
          );
          expect(checked, original);
          expect(checked.first.annotationConfirmation, isNull);
        } finally {
          await analyzer.close();
          await engine.output.close();
        }
      },
    );
    for (final stopAt in [1, 2]) {
      test(
        '${quality.name}: stale generation after search $stopAt publishes no partial window',
        () async {
          var current = true;
          final engine = ConfirmationEngine()
            ..onSearch = (n) {
              if (n == stopAt) current = false;
            };
          final analyzer = StockfishAnalyzer.withFactory(engine.create);
          final original = [review(quality), review(quality, successor: true)];
          try {
            final checked = await analyzer.confirmAnnotations(
              quality: quality,
              scores: original,
              positions: [before, after],
              uciMoves: ['c5a3'],
              classifiedMoves: brilliant,
              scope: MaiaInferenceScope(),
              isCurrent: () => current,
            );
            expect(checked, original);
            expect(engine.searches, stopAt);
          } finally {
            await analyzer.close();
            await engine.output.close();
          }
        },
      );
    }
    test(
      '${quality.name}: second-search failure preserves both original scores',
      () async {
        final engine = ConfirmationEngine()..failAt = 2;
        final analyzer = StockfishAnalyzer.withFactory(engine.create);
        final original = [review(quality), review(quality, successor: true)];
        try {
          final checked = await analyzer.confirmAnnotations(
            quality: quality,
            scores: original,
            positions: [before, after],
            uciMoves: ['c5a3'],
            classifiedMoves: brilliant,
            scope: MaiaInferenceScope(),
            isCurrent: () => true,
          );
          expect(checked, original);
        } finally {
          await analyzer.close();
          await engine.output.close();
        }
      },
    );
  }
  test('provisional worker returns reusable per-run material and default gate stays conservative', () async {
    final inputCache = <String, int>{};
    final provisional = MoveClassifier.startOffMainIsolate(
      scores: [unstable, next],
      positions: [before, after],
      uciMoves: ['c5a3'],
      requireReliableComparisons: false,
      materialCache: inputCache,
    );
    expect(
      (await provisional.result).single.classification,
      MoveClassification.brilliant,
    );
    await provisional.terminated;
    expect(inputCache, isEmpty, reason: 'the worker owns its cache copy');
    expect(provisional.materialCache.keys, unorderedEquals([before, after]));
    expect(() => provisional.materialCache[before] = 0, throwsUnsupportedError);
    final finalJob = MoveClassifier.startOffMainIsolate(
      scores: [unstable, next],
      positions: [before, after],
      uciMoves: ['c5a3'],
      materialCache: provisional.materialCache,
    );
    expect(await finalJob.result, isEmpty);
    await finalJob.terminated;
    expect(finalJob.materialCache, provisional.materialCache);
  });
  test(
    'cancelled provisional worker returns no partial material cache',
    () async {
      final inputCache = {before: 100};
      final job = MoveClassifier.startOffMainIsolate(
        scores: [unstable, next],
        positions: [before, after],
        uciMoves: ['c5a3'],
        requireReliableComparisons: false,
        materialCache: inputCache,
      );
      final cancelled = expectLater(
        job.result,
        throwsA(isA<MoveClassificationCancelled>()),
      );
      job.cancel();
      await cancelled;
      await job.started.timeout(const Duration(seconds: 3));
      await job.terminated.timeout(const Duration(seconds: 3));
      expect(job.materialCache, isEmpty);
      expect(inputCache, {before: 100});
    },
  );
  test(
    'terminal material is finite and mating move is not a sacrifice award',
    () {
      const fen = '7k/5Q2/6K1/8/8/8/8/8 w - - 0 1';
      final game = chess.Chess.fromFEN(fen)..move('Qg7#');
      expect(MoveClassifier.materialEvaluation(game.fen), -10000);
      final labels = MoveClassifier.classify(
        scores: const [
          StockfishReview(
            1000,
            'f7g7',
            mate: 1,
            lines: [
              StockfishLine(evaluation: 0, mate: 1, moves: ['f7g7']),
              StockfishLine(evaluation: 0, moves: ['f7f1']),
            ],
          ),
          StockfishReview(0, '(none)', mate: 1),
        ],
        positions: [fen, game.fen],
        uciMoves: ['f7g7'],
      );
      expect(
        labels.where((m) => m.classification == MoveClassification.brilliant),
        isEmpty,
      );
    },
  );
}
