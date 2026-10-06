import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';

// Longest rare-pause branch: 9s by default, 4.5s in the middle tier, 3s in 1+0.
class LongPauseRandom implements Random {
  int calls = 0;
  @override
  double nextDouble() => (++calls % 4 == 0) ? 0.999999999 : 0;
  @override
  bool nextBool() => throw UnsupportedError('Unexpected RNG use');
  @override
  int nextInt(int max) => throw UnsupportedError('Unexpected RNG use');
}

class ElapsedClock extends Stopwatch {
  ElapsedClock(this.milliseconds);
  int milliseconds;
  @override
  int get elapsedMilliseconds => milliseconds;
  @override
  Duration get elapsed => Duration(milliseconds: milliseconds);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'humanTiming': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  // All records deliberately have 60s left, even in a longer/unlimited game.
  for (final (preset, minutes, increment, waitMillis) in [
    ('bullet', 1, 0, 1000),
    ('custom', 1, 0, 1000),
    ('bulletTwo', 2, 1, 2500),
    ('custom', 2, 1, 2500),
    ('blitzThree', 3, 0, 2500),
    ('custom', 3, 0, 2500),
    ('blitz', 3, 2, 2500),
    ('custom', 3, 2, 2500),
    ('blitzFiveZero', 5, 0, 7000),
    ('custom', 5, 0, 7000),
    ('blitzFive', 5, 3, 7000),
    ('custom', 1, 1, 7000),
    ('rapid', 10, 0, 7000),
    ('unlimited', 0, 0, 7000),
  ]) {
    testWidgets(
      'restored $preset $minutes+$increment selects profile from initial control',
      (tester) async {
        final maia = ControlledMaia();
        final random = LongPauseRandom();
        await ActiveSessionStore.save({
          ...gameRecord(
            preset: preset,
            playerWhite: false,
            white: 60000,
            black: 60000,
          ),
          'customMinutes': minutes,
          'customIncrement': increment,
          'elo': 2600,
        });
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              maiaEvaluator: maia.call,
              clockFactory: () => ElapsedClock(2000),
              humanTimingRandom: random,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(maia.requests, hasLength(1));
        maia.reply('e2e4');
        await tester.pump();
        await tester.pump(Duration(milliseconds: waitMillis - 1));
        expect(find.text('e4'), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        expect(find.text('e4'), findsOneWidget);
        final saved = (await ActiveSessionStore.load())!;
        expect(saved['uciMoves'], ['e2e4']);
        expect(saved['elo'], 2600);
        expect(maia.requests, hasLength(1));
        expect(random.calls, 4);
        await disposeGame(tester);
      },
    );
  }

  for (final (enabled, elapsed) in [(false, 0), (true, 3200)]) {
    testWidgets('bullet adds no wait when enabled=$enabled elapsed=$elapsed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'humanTiming': enabled});
      final maia = ControlledMaia();
      final random = LongPauseRandom();
      await ActiveSessionStore.save(
        gameRecord(
          preset: 'bullet',
          playerWhite: false,
          white: 60000,
          black: 60000,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => ElapsedClock(elapsed),
            humanTimingRandom: random,
          ),
        ),
      );
      await tester.pumpAndSettle();
      maia.reply('e2e4');
      await tester.pump();
      await tester.pump();
      expect(find.text('e4'), findsOneWidget);
      expect(random.calls, enabled ? 4 : 0);
      expect(maia.requests, hasLength(1));
      await disposeGame(tester);
    });
  }

  for (final preset in [TimePreset.bullet, TimePreset.custom]) {
    testWidgets('new $preset 1+0 game uses shortened timing', (tester) async {
      final maia = ControlledMaia();
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            startingFen: AnalysisSession.start().positions.first,
            startingSide: PlayerSide.black,
            startingTimePreset: preset,
            startingCustomMinutes: 1,
            startingCustomIncrement: 0,
            maiaEvaluator: maia.call,
            clockFactory: () => ElapsedClock(0),
            humanTimingRandom: LongPauseRandom(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      maia.reply('e2e4');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2999));
      expect(find.text('e4'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.text('e4'), findsOneWidget);
      expect((await ActiveSessionStore.load())!['timePreset'], preset.name);
      await disposeGame(tester);
    });
  }

  testWidgets(
    'a real timeout during the pause cannot be forgiven or apply a late move',
    (tester) async {
      final maia = ControlledMaia();
      final clocks = <ElapsedClock>[];
      await ActiveSessionStore.save(
        gameRecord(
          preset: 'bullet',
          playerWhite: false,
          white: 1000,
          black: 60000,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () {
              final clock = ElapsedClock(0);
              clocks.add(clock);
              return clock;
            },
            humanTimingRandom: LongPauseRandom(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      maia.reply('e2e4');
      await tester.pump();
      for (final clock in clocks) {
        clock.milliseconds = 1100;
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      final timeout = (await ActiveSessionStore.load())!;
      expect(timeout['forcedResult'], '0-1');
      expect(timeout['whiteMillis'], 0);
      expect(timeout['uciMoves'], isEmpty);
      await tester.pump(const Duration(seconds: 4));
      expect((await ActiveSessionStore.load())!['uciMoves'], isEmpty);
      expect(maia.requests, hasLength(1));
      await disposeGame(tester);
    },
  );

  testWidgets(
    'backgrounding during the bullet wait cannot apply a stale move',
    (tester) async {
      final maia = ControlledMaia();
      await ActiveSessionStore.save(
        gameRecord(
          preset: 'bullet',
          playerWhite: false,
          white: 60000,
          black: 60000,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            maiaEvaluator: maia.call,
            clockFactory: () => ElapsedClock(0),
            humanTimingRandom: LongPauseRandom(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      maia.reply('e2e4');
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 4));
      expect((await ActiveSessionStore.load())!['uciMoves'], isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(maia.requests, hasLength(2));
      await disposeGame(tester);
    },
  );
}
