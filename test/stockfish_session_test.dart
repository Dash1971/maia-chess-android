import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stockfish_failure_test.dart' show FakeStockfish;

class SessionEngine extends FakeStockfish {
  final commands = <String>[];
  bool manual = false;
  bool resetting = false;
  bool holdReset = false;
  List<String>? stopOutput;
  @override
  set stdin(String command) {
    commands.add(command);
    if (command == 'ucinewgame') {
      resetting = true;
    }
    if (command == 'isready' && resetting) {
      resetting = false;
      if (holdReset) {
        return;
      }
    }
    if (manual && command.startsWith('go ')) {
      return;
    }
    if (command == 'stop' && manual) {
      final stopped = stopOutput;
      if (stopped == null) {
        finish(900);
      } else {
        for (final line in stopped) {
          output.add(line);
        }
      }
    }
    super.stdin = command;
  }

  void finish(int cp) {
    output.add('info depth 12 multipv 1 score cp $cp pv e2e4');
    output.add('info depth 12 multipv 2 score cp ${cp - 10} pv d2d4');
    output.add('bestmove e2e4');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(done(), isTrue);
  }

  test(
    'Fast→Thorough→Fast resets once per run, not once per position',
    () async {
      final engine = SessionEngine();
      final analyzer = StockfishAnalyzer.withFactory(engine.create);
      try {
        for (final quality in [
          GameAnalysisQuality.fast,
          GameAnalysisQuality.thorough,
          GameAnalysisQuality.fast,
        ]) {
          final session = Object();
          final first = await analyzer.evaluate(
            chess.Chess.DEFAULT_POSITION,
            analysisSession: session,
            gameAnalysisQuality: quality,
          );
          final second = await analyzer.evaluate(
            chess.Chess.DEFAULT_POSITION,
            analysisSession: session,
            gameAnalysisQuality: quality,
          );
          expect(first.evidence!.reset, isTrue);
          expect(second.evidence!.reset, isFalse);
        }
        expect(engine.commands.where((c) => c == 'ucinewgame').length, 3);
        expect(engine.commands.where((c) => c.startsWith('go ')), [
          for (final q in [
            GameAnalysisQuality.fast,
            GameAnalysisQuality.thorough,
            GameAnalysisQuality.fast,
          ]) ...[q.stockfishCommand, q.stockfishCommand],
        ]);
      } finally {
        await analyzer.close();
        await engine.output.close();
      }
    },
  );
  test('foreground preemption drains old output and resets both ownership switches', () async {
    final engine = SessionEngine()..manual = true;
    final analyzer = StockfishAnalyzer.withFactory(engine.create);
    try {
      final batch = analyzer.evaluate(
        chess.Chess.DEFAULT_POSITION,
        background: true,
        analysisSession: Object(),
      );
      await until(
        () => engine.commands.where((c) => c.startsWith('go ')).length == 1,
      );
      final foreground = analyzer.evaluate(chess.Chess.DEFAULT_POSITION);
      await until(
        () => engine.commands.where((c) => c.startsWith('go ')).length == 2,
      );
      engine.finish(10);
      expect((await foreground).evaluation, 10);
      await until(
        () => engine.commands.where((c) => c.startsWith('go ')).length == 3,
      );
      engine.finish(20);
      expect((await batch).evaluation, 20);
      expect(engine.commands.where((c) => c == 'ucinewgame').length, 3);
      expect(engine.commands.where((c) => c == 'stop').length, 1);
    } finally {
      await analyzer.close();
      await engine.output.close();
    }
  });
  for (final stopped in [
    ['bestmove e2e4'],
    [
      'info depth 1 multipv 1 score cp 300 lowerbound pv e2e4',
      'info depth 1 multipv 2 score cp 0 pv d2d4',
      'bestmove e2e4',
    ],
  ]) {
    test(
      'active cancellation without an exact PV preserves the healthy engine '
      '(${stopped.length == 1 ? "bestmove only" : "bounded primary"})',
      () async {
        final engine = SessionEngine()
          ..manual = true
          ..stopOutput = stopped;
        final analyzer = StockfishAnalyzer.withFactory(engine.create);
        final scope = MaiaInferenceScope();
        try {
          final cancelled = expectLater(
            analyzer.evaluate(chess.Chess.DEFAULT_POSITION, scope: scope),
            throwsA(isA<AnalysisCancelled>()),
          );
          await until(() => engine.commands.any((c) => c.startsWith('go ')));
          analyzer.cancel(scope);
          await cancelled;
          expect(engine.commands.where((c) => c == 'stop').length, 1);
          expect(engine.running, isTrue);
          expect(engine.quits, 0);
          engine.manual = false;
          expect(
            (await analyzer.evaluate(chess.Chess.DEFAULT_POSITION)).evaluation,
            42,
          );
          expect(engine.starts, 1);
          expect(engine.quits, 0);
        } finally {
          await analyzer.close();
          await engine.output.close();
        }
      },
    );
  }
  test(
    'cancelling while reset readiness is pending never starts a stale search',
    () async {
      final engine = SessionEngine()..holdReset = true;
      final analyzer = StockfishAnalyzer.withFactory(engine.create);
      final scope = MaiaInferenceScope();
      try {
        final cancelled = expectLater(
          analyzer.evaluate(
            chess.Chess.DEFAULT_POSITION,
            analysisSession: Object(),
            scope: scope,
          ),
          throwsA(isA<AnalysisCancelled>()),
        );
        await until(() => engine.commands.contains('ucinewgame'));
        analyzer.cancel(scope);
        engine.output.add('readyok');
        await cancelled;
        expect(engine.commands.where((c) => c.startsWith('go ')), isEmpty);
        engine.holdReset = false;
        expect(
          (await analyzer.evaluate(
            chess.Chess.DEFAULT_POSITION,
            analysisSession: Object(),
          )).evaluation,
          42,
        );
      } finally {
        await analyzer.close();
        await engine.output.close();
      }
    },
  );
  test(
    'slow reset readiness is not mistaken for a failed search drain',
    () async {
      final engine = SessionEngine()..holdReset = true;
      final analyzer = StockfishAnalyzer.withFactory(
        engine.create,
        drainTimeout: const Duration(milliseconds: 10),
        readyTimeout: const Duration(milliseconds: 100),
      );
      try {
        final result = analyzer.evaluate(
          chess.Chess.DEFAULT_POSITION,
          analysisSession: Object(),
        );
        await until(() => engine.commands.contains('ucinewgame'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        engine.output.add('readyok');
        expect((await result).evaluation, 42);
        expect(engine.starts, 1);
        expect(engine.quits, 0);
      } finally {
        await analyzer.close();
        await engine.output.close();
      }
    },
  );
  test(
    'failed reset readiness resets native engine and permits retry',
    () async {
      final engine = SessionEngine()..holdReset = true;
      final analyzer = StockfishAnalyzer.withFactory(
        engine.create,
        drainTimeout: const Duration(milliseconds: 10),
        readyTimeout: const Duration(milliseconds: 10),
      );
      try {
        await expectLater(
          analyzer.evaluate(
            chess.Chess.DEFAULT_POSITION,
            analysisSession: Object(),
          ),
          throwsA(isA<TimeoutException>()),
        );
        expect(engine.running, isFalse);
        engine.holdReset = false;
        await analyzer.evaluate(
          chess.Chess.DEFAULT_POSITION,
          analysisSession: Object(),
        );
        expect(engine.starts, 2);
      } finally {
        await analyzer.close();
        await engine.output.close();
      }
    },
  );
}
