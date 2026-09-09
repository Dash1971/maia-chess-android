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
    starts++;
  }

  @override
  Future<void> quit() async {
    quits++;
  }

  @override
  set stdin(String command) {
    if (command == 'isready') output.add('readyok');
    if (command == 'stop' && failStop) {
      throw StateError('native process exited');
    }
    if (command.startsWith('go ')) {
      if (failGo) throw StateError('native process exited');
      if (!hang) {
        output.add('info depth 12 score cp 42 pv e2e4 e7e5');
        output.add('bestmove e2e4');
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
