import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });
  for (final mode in [
    'immediate',
    'background-resume',
    'restored-session',
    'appearance-change',
  ]) {
    testWidgets('completed game analysis Home: $mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final session = AnalysisSession.fromPgn('1. f3 e5 2. g4 Qh4# 0-1');
      await ActiveSessionStore.save({
        'type': 'game',
        'pgn': session.pgn,
        'positions': session.positions,
        'uciMoves': session.uciMoves,
        'playerIsWhite': true,
        'timePreset': 'unlimited',
        'clockPaused': true,
      });
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Analysis Board'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);
      final checkpoint = (await ActiveSessionStore.load())!;
      expect(checkpoint['type'], 'review');
      expect(checkpoint['activeGame'], isA<Map>());
      if (mode == 'appearance-change') {
        final context = tester.element(find.byType(ReviewPage));
        final state = tester.state(find.byType(ReviewPage));
        final appearance = AppAppearanceSettings.maybeOf(context)!;
        for (final theme in [
          const AppAppearance(mode: ThemeMode.light),
          const AppAppearance(systemColors: true, pureBlack: true),
        ]) {
          await appearance.select(theme);
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(ReviewPage)), same(state));
          expect(await ActiveSessionStore.load(), checkpoint);
        }
      }
      if (mode == 'background-resume' || mode == 'restored-session') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        if (mode == 'restored-session') {
          // Resume host-test frames before disposing; paused bindings do not
          // render pumpWidget, so disposing while paused would retain the tree.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          expect(find.byType(GamePage), findsNothing);
          await ActiveSessionStore.save(checkpoint);
          await tester.pumpWidget(const MaiaChessApp());
        }
        await tester.pumpAndSettle();
      }
      expect(find.byType(ReviewPage), findsOneWidget);
      expect(
        tester.widget<ReviewPage>(find.byType(ReviewPage)).returnToGame,
        false,
      );
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Start game'), findsOneWidget);
      expect(find.byKey(const ValueKey('game-home-button')), findsNothing);
      expect(await ActiveSessionStore.load(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
  for (final hasActiveGame in [false, true]) {
    testWidgets('restored unfinished review (activeGame=$hasActiveGame)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final session = AnalysisSession.fromPgn('1. e4 e5 *');
      await ActiveSessionStore.save({
        'type': 'review',
        'session': session.toJson(),
        'playerIsWhite': true,
        if (hasActiveGame)
          'activeGame': {
            'type': 'game',
            'pgn': session.pgn,
            'positions': session.positions,
            'uciMoves': session.uciMoves,
            'playerIsWhite': true,
            'timePreset': 'unlimited',
            'clockPaused': true,
          },
      });
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      expect(
        tester.widget<ReviewPage>(find.byType(ReviewPage)).returnToGame,
        hasActiveGame,
      );
      await tester.tap(find.byTooltip(hasActiveGame ? 'Back to game' : 'Home'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsNothing);
      if (hasActiveGame) {
        expect(find.byKey(const ValueKey('game-home-button')), findsOneWidget);
        expect(find.text('Start game'), findsNothing);
        final saved = (await ActiveSessionStore.load())!;
        expect(saved['type'], 'game');
        expect(saved['uciMoves'], session.uciMoves);
        expect(saved['forcedResult'], isNull);
      } else {
        expect(find.text('Start game'), findsOneWidget);
        expect(await ActiveSessionStore.load(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
