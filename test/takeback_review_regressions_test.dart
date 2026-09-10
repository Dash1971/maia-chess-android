import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';
import 'fixtures/nested_takeback_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'humanTiming': false,
      'temperatureV2': 0.0,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> action(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  // Inspect PGN nodes directly, independently of the app's variation parser.
  void expectSingleAbandonedLine(String pgn) {
    final moves = dc.PgnGame.parsePgn(pgn).moves;
    var parent = moves;
    for (var ply = 0; ply < 23; ply++) {
      parent = parent.children.first;
    }
    expect(parent.children, hasLength(2));
    final line = parent.children[1];
    expect(
      [line.data.san, ...line.mainline().map((n) => n.san)],
      ['Qxe7', 'Qe2', 'Qd7', 'Qe3'],
    );
    expect(RegExp('Queen note').allMatches(pgn), hasLength(1));
    expect(RegExp('Reply note').allMatches(pgn), hasLength(1));
  }

  testWidgets('nested takebacks stay unique through review visits and reopen', (
    tester,
  ) async {
    final maia = ControlledMaia();
    await ActiveSessionStore.save(
      gameRecord(
        pgn: nestedTakebackGame,
        playerWhite: false,
        white: 300000,
        black: 300000,
        history: [
          for (var i = 0; i <= 27; i++) [300000 + i * 37, 300000 + i * 43],
        ],
      ),
    );
    Future<void> open() async {
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => TestClock(0),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();
    await action(tester, 'Take back move');
    expect((await ActiveSessionStore.load())!['uciMoves'], hasLength(25));
    await action(tester, 'Take back move');
    expect((await ActiveSessionStore.load())!['uciMoves'], hasLength(23));
    boardOf(tester).onMove!(dc.NormalMove.fromUci('d8e7'));
    await tester.pumpAndSettle();
    maia.reply('g1g2');
    await tester.pumpAndSettle();
    final before = (await ActiveSessionStore.load())!;
    expectSingleAbandonedLine(before['pgn'] as String);
    for (var visit = 0; visit < 8; visit++) {
      await action(tester, 'Analysis Board');
      expect(find.byType(ReviewPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(ReviewPage))).pop();
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expectSingleAbandonedLine(saved['pgn'] as String);
      for (final key in [
        'uciMoves',
        'positions',
        'clockHistory',
        'whiteMillis',
        'blackMillis',
        'pgn',
      ]) {
        expect(saved[key], before[key], reason: 'visit $visit: $key');
      }
      if (visit.isOdd) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pumpAndSettle();
        await disposeGame(tester);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await open();
      }
    }
    await disposeGame(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'previously duplicated saved PGN is repaired without losing notes',
    (tester) async {
      await ActiveSessionStore.save(
        gameRecord(
          pgn: duplicatedTakebackGame.replaceFirst('*', '1-0'),
          playerWhite: false,
          result: '1-0',
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expectSingleAbandonedLine(saved['pgn'] as String);
      expect(
        AnalysisSession.fromPgn(saved['pgn'] as String).uciMoves,
        hasLength(25),
      );
      expect(saved['forcedResult'], '1-0');
      await disposeGame(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
