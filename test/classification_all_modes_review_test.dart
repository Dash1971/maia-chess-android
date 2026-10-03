import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

const _before =
    'r2q1rk1/pp2ppbp/2p2np1/2Q3B1/n2PP1b1/2N2N2/PP3PPP/3RKB1R w K - 7 12';
const _after =
    'r2q1rk1/pp2ppbp/2p2np1/6B1/n2PP1b1/Q1N2N2/PP3PPP/3RKB1R b K - 8 12';

StockfishReview _spike(GameAnalysisQuality quality) => StockfishReview(
  300,
  'c5a3',
  lines: const [
    StockfishLine(evaluation: 300, moves: ['c5a3']),
    StockfishLine(evaluation: -10, moves: ['c5b4']),
  ],
  evidence: StockfishSearchEvidence(
    depth: 24,
    nodes: 100000,
    timeMs: 500,
    complete: true,
    reset: true,
    quality: quality,
    previousLines: const [
      StockfishLine(evaluation: 0, moves: ['c5a3']),
      StockfishLine(evaluation: -10, moves: ['c5b4']),
    ],
  ),
);

StockfishReview _review(
  GameAnalysisQuality quality,
  int cp,
  int previousCp, {
  String move = 'c5a3',
  int? secondCp,
  int depth = 24,
}) {
  final current = [
    StockfishLine(evaluation: cp, moves: [move]),
    StockfishLine(evaluation: secondCp ?? cp - 300, moves: ['c5b4']),
  ];
  return StockfishReview(
    cp,
    move,
    lines: current,
    evidence: StockfishSearchEvidence(
      depth: depth,
      nodes: 100000,
      timeMs: 500,
      complete: true,
      reset: true,
      quality: quality,
      previousLines: [
        StockfishLine(evaluation: previousCp, moves: [move]),
        StockfishLine(
          evaluation: secondCp ?? previousCp - 300,
          moves: ['c5b4'],
        ),
      ],
    ),
  );
}

void main() {
  for (final quality in GameAnalysisQuality.values) {
    test(
      '${quality.name}: mismatched baseline quality cannot establish stability',
      () {
        final other = GameAnalysisQuality.values.firstWhere(
          (q) => q != quality,
        );
        final before = _review(quality, 300, 300, secondCp: -10);
        final after = _review(other, 300, 300, move: 'a4c3');
        expect(
          MoveClassifier.hasReliableAnnotation(
            scores: [before, after],
            positions: const [_before, _after],
            uciMoves: const ['c5a3'],
            ply: 1,
            classification: MoveClassification.brilliant,
          ),
          isFalse,
        );
      },
    );
    for (final invalidQuality in [false, true]) {
      test(
        '${quality.name}: independent ${invalidQuality ? "wrong quality" : "shallower depth"} cannot establish award',
        () {
          final other = GameAnalysisQuality.values.firstWhere(
            (q) => q != quality,
          );
          final before = _review(quality, 300, 300, secondCp: -10);
          final after = _review(quality, 300, 300, move: 'a4c3');
          final checked = _review(
            invalidQuality ? other : quality,
            300,
            300,
            secondCp: -10,
            depth: invalidQuality ? 24 : 23,
          );
          final attached = before.withAnnotationConfirmation(
            StockfishAnnotationConfirmation(before: checked, after: after),
          );
          expect(
            MoveClassifier.hasReliableAnnotation(
              scores: [attached, after],
              positions: const [_before, _after],
              uciMoves: const ['c5a3'],
              ply: 1,
              classification: MoveClassification.brilliant,
            ),
            isFalse,
          );
        },
      );
    }
    test(
      '${quality.name}: adjacent annotations retain independent windows',
      () {
        final firstBefore = _review(quality, 0, 0, secondCp: -300);
        final sharedBaseline = _review(
          quality,
          0,
          0,
          move: 'a4c3',
          secondCp: 300,
        );
        final finalBaseline = _review(quality, 0, 0);
        final firstConfirmed = firstBefore.withAnnotationConfirmation(
          StockfishAnnotationConfirmation(
            before: firstBefore,
            after: sharedBaseline,
          ),
        );
        final secondConfirmed = sharedBaseline.withAnnotationConfirmation(
          StockfishAnnotationConfirmation(
            before: sharedBaseline,
            after: finalBaseline,
          ),
        );
        final scores = [firstConfirmed, secondConfirmed, finalBaseline];
        for (final ply in [1, 2]) {
          expect(
            MoveClassifier.hasReliableAnnotation(
              scores: scores,
              positions: const [_before, _after, _before],
              uciMoves: const ['c5a3', 'a4c3'],
              ply: ply,
              classification: MoveClassification.brilliant,
            ),
            isTrue,
          );
        }
        expect(scores[0].evaluation, firstBefore.evaluation);
        expect(scores[1].lines, same(sharedBaseline.lines));
        expect(scores[0].annotationConfirmation!.after, same(sharedBaseline));
        expect(scores[1].annotationConfirmation!.before, same(sharedBaseline));
      },
    );
    test(
      '${quality.name}: stable before cannot hide an unstable successor',
      () {
        final before = _review(quality, 300, 300, secondCp: -10);
        final after = _review(quality, 300, -300, move: 'a4c3');
        expect(
          MoveClassifier.hasReliableAnnotation(
            scores: [before, after],
            positions: const [_before, _after],
            uciMoves: const ['c5a3'],
            ply: 1,
            classification: MoveClassification.brilliant,
          ),
          isFalse,
        );
      },
    );
    test(
      '${quality.name}: Good verifies its preceding-position improvement',
      () {
        final beforePrevious = _review(quality, 0, 300);
        final before = _review(quality, 300, 300, secondCp: -10);
        final after = _review(quality, 300, 300, move: 'a4c3');
        expect(
          MoveClassifier.hasReliableAnnotation(
            scores: [beforePrevious, before, after],
            positions: const [_before, _before, _after],
            uciMoves: const ['unused', 'c5a3'],
            ply: 2,
            classification: MoveClassification.good,
          ),
          isFalse,
        );
      },
    );
    test(
      '${quality.name}: independent counterexample overrides stable iterations',
      () {
        final before = _review(quality, 300, 300, secondCp: -10);
        final after = _review(quality, 300, 300, move: 'a4c3');
        final refuted = before.withAnnotationConfirmation(
          StockfishAnnotationConfirmation(
            before: _review(quality, 0, 0, secondCp: -10),
            after: after,
          ),
        );
        expect(refuted.evaluation, before.evaluation);
        expect(refuted.lines, same(before.lines));
        expect(
          MoveClassifier.hasReliableAnnotation(
            scores: [refuted, after],
            positions: const [_before, _after],
            uciMoves: const ['c5a3'],
            ply: 1,
            classification: MoveClassification.brilliant,
          ),
          isFalse,
        );
      },
    );
    test(
      '${quality.name}: full-window agreement permits upstream Brilliant',
      () {
        final before = _review(quality, 300, 300, secondCp: -10);
        final after = _review(quality, 300, 300, move: 'a4c3');
        expect(
          MoveClassifier.hasReliableAnnotation(
            scores: [before, after],
            positions: const [_before, _after],
            uciMoves: const ['c5a3'],
            ply: 1,
            classification: MoveClassification.brilliant,
          ),
          isTrue,
        );
      },
    );
    test(
      '${quality.name}: final-iteration Qa3 spike is not a verified award',
      () {
        final scores = [_spike(quality), const StockfishReview(300, 'a4c3')];
        // The upstream formula awards Brilliant for these exact scores. That
        // parity is distinct from the production evidence policy: a large depth
        // or a quality name alone cannot validate a newly appearing score gap.
        final raw = MoveClassifier.classify(
          scores: scores,
          positions: const [_before, _after],
          uciMoves: const ['c5a3'],
          requireReliableComparisons: false,
        );
        expect(raw.single.classification, MoveClassification.brilliant);
        final guarded = MoveClassifier.classify(
          scores: scores,
          positions: const [_before, _after],
          uciMoves: const ['c5a3'],
        );
        expect(guarded, isEmpty);
      },
    );
  }
}
