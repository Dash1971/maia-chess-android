import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stockfish_failure_test.dart' show FakeStockfish;

class StreamFailureEngine extends FakeStockfish {
  bool failStream = true;
  bool endStream = false;
  @override
  set stdin(String command) {
    if (command.startsWith('go ') && failStream) {
      if (endStream) {
        output.close();
      } else {
        output.addError(StateError('native stream failure'));
      }
      return;
    }
    super.stdin = command;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<StockfishReview> replay(List<String> info) async {
    final engine = FakeStockfish()..searchOutput = [...info, 'bestmove e2e4'];
    final analyzer = StockfishAnalyzer.withFactory(engine.create);
    try {
      return await analyzer.evaluate(chess.Chess.DEFAULT_POSITION);
    } finally {
      await analyzer.close();
      await engine.output.close();
    }
  }

  test(
    'native stream error fails promptly and recovers on the next search',
    () async {
      final engine = StreamFailureEngine();
      final analyzer = StockfishAnalyzer.withFactory(engine.create);
      try {
        await expectLater(
          analyzer.evaluate(chess.Chess.DEFAULT_POSITION),
          throwsStateError,
        );
        expect(engine.running, isFalse);
        engine.failStream = false;
        expect(
          (await analyzer.evaluate(chess.Chess.DEFAULT_POSITION)).evaluation,
          42,
        );
        expect(engine.starts, 2);
      } finally {
        await analyzer.close();
        await engine.output.close();
      }
    },
  );
  test('native stdout EOF resets the engine instead of timing out', () async {
    final broken = StreamFailureEngine()..endStream = true;
    final replacement = FakeStockfish();
    var count = 0;
    final analyzer = StockfishAnalyzer.withFactory(
      () => count++ == 0 ? broken.create() : replacement.create(),
    );
    try {
      await expectLater(
        analyzer.evaluate(chess.Chess.DEFAULT_POSITION),
        throwsStateError,
      );
      expect(
        (await analyzer.evaluate(chess.Chess.DEFAULT_POSITION)).evaluation,
        42,
      );
    } finally {
      await analyzer.close();
      await broken.output.close();
      await replacement.output.close();
    }
  });
  const first = 'info depth 12 multipv 1 score cp 0 pv e2e4';
  const second = 'info depth 12 multipv 2 score cp -10 pv d2d4';
  test(
    'partial next depth cannot replace either score of a completed pair',
    () async {
      final review = await replay([
        first,
        second,
        'info depth 13 multipv 1 score cp 300 pv e2e4',
      ]);
      expect(review.evaluation, 0);
      expect(review.lines.map((line) => line.evaluation), [0, -10]);
      expect(review.evidence!.depth, 12);
    },
  );
  for (final tail in [
    [
      'info depth 13 multipv 1 score cp 300 lowerbound pv e2e4',
      'info depth 13 multipv 2 score cp -20 pv d2d4',
    ],
    [
      'info depth 13 multipv 1 score cp 300 pv e2e4',
      'info depth 13 multipv 2 score cp -20 pv e2e4',
    ],
    ['info depth 13 multipv 2 score cp -20 pv d2d4'],
    [
      'info depth 11 multipv 1 score cp 300 pv e2e4',
      'info depth 11 multipv 2 score cp -20 pv d2d4',
    ],
    [
      'info depth 13 multipv 1 score cp 300 pv a1a8',
      'info depth 13 multipv 2 score cp -20 pv d2d4',
    ],
    [
      'info depth 13 multipv 1 score cp 300',
      'info depth 13 multipv 2 score cp -20 pv d2d4',
    ],
  ]) {
    test('reject incomplete/invalid comparison ${tail.join(";")}', () async {
      final review = await replay([first, second, ...tail]);
      expect(review.lines.map((line) => line.evaluation), [0, -10]);
    });
  }
  test(
    'info arriving after bestmove cannot mutate the completed result',
    () async {
      final result = await replay([
        first,
        second,
        'bestmove e2e4',
        'info depth 13 multipv 1 score cp 300 pv e2e4',
        'info depth 13 multipv 2 score cp -10 pv d2d4',
      ]);
      expect(result.evaluation, 0);
      expect(result.evidence!.depth, 12);
    },
  );
  test('reordered ranks form one coherent snapshot', () async {
    final review = await replay([second, first]);
    expect(review.lines.map((line) => line.evaluation), [0, -10]);
  });
  test('repeated rank starts a fresh iteration', () async {
    final review = await replay([
      first,
      first.replaceFirst('cp 0', 'cp 20'),
      second,
    ]);
    expect(review.evaluation, 20);
  });
  test(
    'a primary alone is useful but cannot award comparison labels',
    () async {
      final review = await replay([first]);
      expect(review.lines.length, 1);
      expect(review.evidence!.complete, isFalse);
    },
  );
  test(
    'bound-only or missing scores fail instead of inventing equality',
    () async {
      await expectLater(
        replay(['info depth 12 score cp 800 lowerbound pv e2e4']),
        throwsStateError,
      );
      await expectLater(replay([]), throwsStateError);
    },
  );
  test('mate and scalar scores come from the same completed depth', () async {
    final review = await replay([
      first.replaceFirst('cp 0', 'mate 3'),
      second,
      'info depth 13 multipv 1 score cp 1 pv e2e4',
    ]);
    expect(review.mate, 3);
    expect(review.lines.first.mate, 3);
  });
  test('one legal reply completes MultiPV without fabricating another', () {
    final snapshots = StockfishSearchSnapshots(legalMoves: {'h1g1'});
    snapshots.add('info depth 12 score cp -400 pv h1g1');
    expect(snapshots.completed!.lines.length, 1);
  });
}
