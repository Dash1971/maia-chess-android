import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  test(
    'time controls are ordered and existing saved names retain their meaning',
    () {
      expect(TimePreset.values.map((p) => p.label), [
        'Unlimited',
        '1 + 0',
        '2 + 1',
        '3 + 0',
        '3 + 2',
        '5 + 0',
        '5 + 3',
        '10 + 0',
        '10 + 5',
        '15 + 10',
        '30 + 0',
        '30 + 20',
        'Custom',
      ]);
      for (final (name, minutes, increment) in [
        ('bullet', 1, 0),
        ('bulletTwo', 2, 1),
        ('blitzThree', 3, 0),
        ('blitzFiveZero', 5, 0),
        ('blitz', 3, 2),
        ('blitzFive', 5, 3),
        ('rapid', 10, 0),
        ('classical', 15, 10),
        ('rapidFive', 10, 5),
        ('classicalThirty', 30, 0),
        ('classicalThirtyTwenty', 30, 20),
      ]) {
        final preset = TimePreset.values.byName(name);
        expect((preset.minutes, preset.increment), (minutes, increment));
      }
    },
  );

  testWidgets('long dropdown scrolls to 30+20 on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: GamePage(maiaEvaluator: ControlledMaia().call)),
    );
    await tester.pumpAndSettle();
    final control = find.byType(DropdownButtonFormField<TimePreset>);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('30 + 20'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 + 20').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('time-preset-classicalThirtyTwenty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await disposeGame(tester);
  });

  for (final preset in [
    TimePreset.bulletTwo,
    TimePreset.blitzThree,
    TimePreset.blitzFiveZero,
    TimePreset.rapidFive,
    TimePreset.classicalThirty,
    TimePreset.classicalThirtyTwenty,
  ]) {
    testWidgets(
      '${preset.label} selects, persists, applies increment and restores',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final maia = ControlledMaia();
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
        await tester.tap(find.byType(DropdownButtonFormField<TimePreset>));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(preset.label),
          80,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(preset.label).last);
        await tester.pumpAndSettle();
        expect(
          (await SharedPreferences.getInstance()).getString(
            maiaTimePresetPreferenceKey,
          ),
          preset.name,
        );
        await disposeGame(tester);
        await open();
        expect(
          find.byKey(ValueKey('time-preset-${preset.name}')),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
        await tester.pumpAndSettle();
        var saved = (await ActiveSessionStore.load())!;
        expect(saved['timePreset'], preset.name);
        expect(saved['whiteMillis'], preset.minutes * 60000);
        expect(saved['blackMillis'], preset.minutes * 60000);
        await queueMove(tester, 'e2e4');
        saved = (await ActiveSessionStore.load())!;
        expect(saved['uciMoves'], ['e2e4']);
        expect(
          saved['whiteMillis'],
          preset.minutes * 60000 + preset.increment * 1000,
        );
        await disposeGame(tester);
        await open();
        expect(find.text('e4'), findsOneWidget);
        expect((await ActiveSessionStore.load())!['timePreset'], preset.name);
        expect(tester.takeException(), isNull);
        await disposeGame(tester);
      },
    );

    testWidgets('${preset.label} is available in Continue from here', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: AnalysisSession.start(),
            maiaElo: 1600,
            evaluator: (_) async => const StockfishReview(0, 'e2e4'),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analysis-actions-menu')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue from here'));
      await tester.tap(find.text('Continue from here'));
      await tester.pumpAndSettle();
      final control = find.byKey(const ValueKey('continuation-time-control'));
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(preset.label),
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(preset.label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('continuation-start-game')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<GamePage>(find.byType(GamePage)).startingTimePreset,
        preset,
      );
      final saved = (await ActiveSessionStore.load())!;
      expect(saved['timePreset'], preset.name);
      expect(saved['blackMillis'], preset.minutes * 60000);
      expect(tester.takeException(), isNull);
      await disposeGame(tester);
    });
  }
}
