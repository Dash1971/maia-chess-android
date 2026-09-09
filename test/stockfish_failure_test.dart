import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:multistockfish/multistockfish.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeStockfish implements Stockfish {
  final output = StreamController<String>.broadcast();
  int starts = 0;
  int quits = 0;
  bool failGo = false;
  bool failStop = false;
  bool failReady = false;
  bool ignoreReady = false;
  bool running = false;
  List<String>? searchOutput;
  bool hang = false;
  @override
  Stream<String> get stdout => output.stream;
  @override
  Future<void> start({
    StockfishFlavor flavor = StockfishFlavor.sf16,
    String? variant,
    String? smallNetPath,
    String? bigNetPath,
  }) async {
    if (running) throw StateError('Stockfish is already running');
    starts++;
    running = true;
  }

  @override
  Future<void> quit() async {
    quits++;
    running = false;
  }

  @override
  set stdin(String command) {
    if (command == 'isready') {
      if (failReady) throw StateError('native readiness write failed');
      if (!ignoreReady) output.add('readyok');
    }
    if (command == 'stop' && failStop) {
      throw StateError('native process exited');
    }
    if (command.startsWith('go ')) {
      if (failGo) throw StateError('native process exited');
      if (!hang) {
        for (final line
            in searchOutput ??
                ['info depth 12 score cp 42 pv e2e4 e7e5', 'bestmove e2e4']) {
          output.add(line);
        }
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final black in [false, true]) {
    test('Stockfish scores and both PVs use White perspective (${black ? 'Black' : 'White'} to move)', () async {
      final engine = FakeStockfish()
        ..searchOutput = [
          'info depth 12 multipv 2 score cp -30 pv ${black ? 'd7d5 d2d4' : 'd2d4 d7d5'}',
          'info depth 12 multipv 1 score cp 42 pv ${black ? 'e7e5 e2e4' : 'e2e4 e7e5'}',
          'bestmove ${black ? 'e7e5' : 'e2e4'}',
        ];
      final analyzer = StockfishAnalyzer.withEngine(engine);
      final fen = chess.Chess.DEFAULT_POSITION.replaceFirst(
        ' w ',
        black ? ' b ' : ' w ',
      );
      final result = await analyzer.evaluate(fen);
      expect(result.evaluation, black ? -42 : 42);
      expect(
        result.lines.map((line) => line.evaluation),
        black ? [-42, 30] : [42, -30],
      );
      engine.searchOutput = [
        'info depth 14 score cp 42 pv ${black ? 'e7e5' : 'e2e4'}',
        'info depth 15 score mate -2 pv ${black ? 'e7e5' : 'e2e4'}',
        'bestmove ${black ? 'e7e5' : 'e2e4'}',
      ];
      final mate = await analyzer.evaluate(fen);
      expect(mate.mate, black ? 2 : -2);
      expect(mate.lines.single.mate, black ? 2 : -2);
      await analyzer.close();
      await engine.output.close();
    });
  }
  for (final missingReply in [false, true]) {
    test(
      'startup ${missingReply ? 'timeout' : 'write failure'} recovers',
      () async {
        final engine = FakeStockfish()
          ..failReady = !missingReply
          ..ignoreReady = missingReply;
        final analyzer = StockfishAnalyzer.withEngine(engine);
        await expectLater(
          analyzer.evaluate(chess.Chess.DEFAULT_POSITION),
          throwsA(missingReply ? isA<TimeoutException>() : isA<StateError>()),
        );
        final leaked = engine.output.hasListener;
        final reset = !engine.running;
        // Complete any orphaned readiness future in the unfixed implementation
        // so the regression failure itself does not leak into another test.
        engine.output.add('readyok');
        await Future<void>.delayed(Duration.zero);
        engine.failReady = false;
        engine.ignoreReady = false;
        StockfishReview? recovered;
        try {
          recovered = await analyzer.evaluate(chess.Chess.DEFAULT_POSITION);
        } catch (_) {
          // Checked after cleanup below.
        }
        await analyzer.close();
        await engine.quit();
        await engine.output.close();
        expect(leaked, isFalse, reason: 'readiness listener must be cancelled');
        expect(
          reset,
          isTrue,
          reason: 'failed startup must quit the live process',
        );
        expect(recovered?.evaluation, 42);
      },
    );
  }
  test(
    'native go failure removes its listener and restarts for the next request',
    () async {
      final engine = FakeStockfish()..failGo = true;
      final analyzer = StockfishAnalyzer.withEngine(engine);
      await expectLater(
        analyzer.evaluate(chess.Chess.DEFAULT_POSITION),
        throwsStateError,
      );
      final leaked = engine.output.hasListener;
      engine.failGo = false;
      final result = await analyzer.evaluate(chess.Chess.DEFAULT_POSITION);
      final starts = engine.starts;
      await analyzer.close();
      await engine.output.close();
      expect(leaked, isFalse);
      expect(starts, 2);
      expect(result.evaluation, 42);
    },
  );
  test(
    'timeout followed by a failed stop resets the engine before retry',
    () async {
      final engine = FakeStockfish()
        ..hang = true
        ..failStop = true;
      final analyzer = StockfishAnalyzer.withEngine(
        engine,
        searchTimeout: const Duration(milliseconds: 20),
        drainTimeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        analyzer.evaluate(chess.Chess.DEFAULT_POSITION),
        throwsA(anyOf(isA<TimeoutException>(), isA<StateError>())),
      );
      engine.hang = false;
      engine.failStop = false;
      await analyzer.evaluate(chess.Chess.DEFAULT_POSITION);
      final starts = engine.starts;
      await analyzer.close();
      await engine.output.close();
      expect(starts, 2);
    },
  );
}
