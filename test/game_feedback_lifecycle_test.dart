import 'dart:async';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DelayedSounds extends SoundEffect {
  final ready = Completer<void>();
  final played = <String>[];
  int initializations = 0;

  @override
  Future<void> initialize({int maxStreams = 1}) async {
    initializations++;
  }

  @override
  Future<void> load(String soundId, String path) => ready.future;

  @override
  Future<void> play(String soundId, {double volume = 1}) async {
    played.add(soundId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({gameSoundsPreferenceKey: true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  test(
    'cancelled loading does not replay, and later valid sounds still work',
    () async {
      final sounds = DelayedSounds();
      final service = GameFeedbackService(soundEffect: sounds);
      var current = true;
      await service.play(
        GameFeedbackEvent.move,
        soundsEnabled: true,
        hapticsEnabled: false,
        isCurrent: () => current,
      );
      current = false;
      sounds.ready.complete();
      await Future<void>.delayed(Duration.zero);
      expect(sounds.played, isEmpty);
      await service.play(
        GameFeedbackEvent.capture,
        soundsEnabled: true,
        hapticsEnabled: false,
        isCurrent: () => true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(sounds.played, ['capture']);
      expect(sounds.initializations, 1);
    },
  );

  for (final action in [
    'none',
    'background',
    'background-resume',
    'route',
    'history',
    'dispose',
  ]) {
    testWidgets('delayed move audio after $action', (tester) async {
      final sounds = DelayedSounds();
      final navigator = GlobalKey<NavigatorState>();
      final maia = Completer<Float32List>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [maiaRouteObserver],
          home: GamePage(
            startingFen: chess.Chess.DEFAULT_POSITION,
            startingSide: PlayerSide.white,
            maiaEvaluator: (_, _) => maia.future,
            gameFeedbackService: GameFeedbackService(soundEffect: sounds),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
        dc.NormalMove.fromUci('e2e4'),
      );
      await tester.pump();
      await tester.pump();
      expect(sounds.initializations, 1);
      expect(sounds.played, isEmpty);
      switch (action) {
        case 'background':
        case 'background-resume':
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          if (action == 'background-resume') {
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
          }
        case 'route':
          unawaited(
            navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Another page')),
              ),
            ),
          );
          await tester.pumpAndSettle();
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
        case 'history':
          await tester.tap(
            find.byKey(const ValueKey('game-previous-move-button')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('game-next-move-button')));
          await tester.pumpAndSettle();
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'none':
          break;
      }
      sounds.ready.complete();
      await tester.pump();
      await tester.pump();
      expect(sounds.played, action == 'none' ? ['move'] : isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    });
  }

  for (final enterAnalysis in [false, true]) {
    testWidgets(
      'game-end feedback ${enterAnalysis ? 'cancels in analysis' : 'plays once in game'}',
      (tester) async {
        final events = <GameFeedbackEvent>[];
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              startingFen: '8/8/8/8/8/6k1/4r3/4R1K1 b - - 0 1',
              startingSide: PlayerSide.black,
              gameFeedbackPlayer: (event, _, _) async => events.add(event),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
          dc.NormalMove.fromUci('e2e1'),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(events, [GameFeedbackEvent.captureCheck]);
        expect(
          find.byKey(const ValueKey('game-conclusion-dialog')),
          findsOneWidget,
        );
        if (enterAnalysis) {
          await tester.tap(find.widgetWithText(TextButton, 'Analysis Board'));
          await tester.pump();
          await tester.pump();
          expect(find.byType(ReviewPage), findsOneWidget);
        }
        events.clear();
        await tester.pump(const Duration(milliseconds: 600));
        expect(events, enterAnalysis ? isEmpty : [GameFeedbackEvent.gameEnd]);
        await tester.pump(const Duration(seconds: 1));
        expect(events, enterAnalysis ? isEmpty : [GameFeedbackEvent.gameEnd]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets('history long press respects disabled phone feedback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      gameSoundsPreferenceKey: false,
      gameHapticsPreferenceKey: false,
    });
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate' ||
            call.method == 'SystemSound.play') {
          calls.add(call);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final maia = Completer<Float32List>();
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          startingFen: chess.Chess.DEFAULT_POSITION,
          startingSide: PlayerSide.white,
          maiaEvaluator: (_, _) => maia.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
      dc.NormalMove.fromUci('e2e4'),
    );
    await tester.pump();
    await tester.pump();
    await tester.longPress(
      find.byKey(const ValueKey('game-previous-move-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('START'), findsOneWidget);
    expect(calls, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
