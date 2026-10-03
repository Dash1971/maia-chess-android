import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  const fen =
      '2rq1b1r/p1k5/b1np1p2/Pp1BPppp/2p1nPPP/BPPP1Q2/3N4/R3KR2 w - - 4 23';

  MoveClassificationJob heavyJob() {
    final game = chess.Chess.fromFEN(fen);
    expect(game.move('Bxc6'), isTrue);
    return MoveClassifier.startOffMainIsolate(
      scores: const [
        StockfishReview(
          0,
          'd5c6',
          lines: [
            StockfishLine(evaluation: 0, moves: ['d5c6']),
            StockfishLine(evaluation: 0, moves: ['a1b1']),
          ],
        ),
        StockfishReview(0, 'a7a6'),
      ],
      positions: [fen, game.fen],
      uciMoves: const ['d5c6'],
    );
  }

  test('cancel before spawn finishes still terminates the worker', () async {
    final job = heavyJob();
    final cancelled = expectLater(
      job.result,
      throwsA(isA<MoveClassificationCancelled>()),
    );
    job.cancel();
    await cancelled;
    await job.started.timeout(const Duration(seconds: 3));
    await job.terminated.timeout(const Duration(seconds: 3));
  });

  test(
    'cancel running worker and replacement without leaving an orphan',
    () async {
      final first = heavyJob();
      final firstCancelled = expectLater(
        first.result,
        throwsA(isA<MoveClassificationCancelled>()),
      );
      await first.started.timeout(const Duration(seconds: 3));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      first.cancel();
      await firstCancelled;
      await first.terminated.timeout(const Duration(seconds: 3));

      final replacement = heavyJob();
      final replacementCancelled = expectLater(
        replacement.result,
        throwsA(isA<MoveClassificationCancelled>()),
      );
      await replacement.started.timeout(const Duration(seconds: 3));
      replacement.cancel();
      await replacementCancelled;
      await replacement.terminated.timeout(const Duration(seconds: 3));
    },
  );

  test('cancel after completed work preserves the completed result', () async {
    final job = MoveClassifier.startOffMainIsolate(
      scores: const [StockfishReview(0, ''), StockfishReview(-300, '')],
      positions: const [
        chess.Chess.DEFAULT_POSITION,
        chess.Chess.DEFAULT_POSITION,
      ],
      uciMoves: const ['f2f3'],
    );
    final result = await job.result;
    job.cancel();
    await job.terminated;
    expect(result.single.classification, MoveClassification.blunder);
  });

  test('short worker finish/cancel races always release the isolate', () async {
    final game = chess.Chess()..move('e4');
    for (var attempt = 0; attempt < 8; attempt++) {
      final job = MoveClassifier.startOffMainIsolate(
        scores: const [
          StockfishReview(
            0,
            'e2e4',
            lines: [
              StockfishLine(evaluation: 0, moves: ['e2e4']),
              StockfishLine(evaluation: -20, moves: ['d2d4']),
            ],
          ),
          StockfishReview(0, 'e7e5'),
        ],
        positions: [chess.Chess.DEFAULT_POSITION, game.fen],
        uciMoves: const ['e2e4'],
      );
      final outcome = job.result.then<Object>(
        (value) => value,
        onError: (Object error) => error,
      );
      await job.started;
      await Future<void>.delayed(Duration.zero);
      job.cancel();
      final result = await outcome.timeout(const Duration(seconds: 3));
      expect(
        result is List<ClassifiedMove> || result is MoveClassificationCancelled,
        isTrue,
      );
      await job.terminated.timeout(const Duration(seconds: 3));
    }
  });

  test('worker failure completes and releases its isolate', () async {
    final job = MoveClassifier.startOffMainIsolate(
      scores: const [
        StockfishReview(
          0,
          'e2e4',
          lines: [
            StockfishLine(evaluation: 0, moves: ['e2e4']),
            StockfishLine(evaluation: -20, moves: ['d2d4']),
          ],
        ),
        StockfishReview(0, 'e7e5'),
      ],
      positions: const ['', ''],
      uciMoves: const ['e2e4'],
    );
    await expectLater(job.result, throwsStateError);
    await job.terminated.timeout(const Duration(seconds: 3));
  });
}
