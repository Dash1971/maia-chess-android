import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home focuses on setup and three large actions', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();

    expect(find.text('Play Maia'), findsOneWidget);
    expect(find.text('Play a human-like opponent'), findsNothing);
    expect(find.textContaining('runs entirely on your phone'), findsNothing);
    expect(find.text('Open PGN file'), findsNothing);
    expect(find.text('Advanced'), findsNothing);
    expect(
      find.byKey(const ValueKey('home-chessnut-toggle')).hitTestable(),
      findsOneWidget,
    );

    for (final label in ['Start game', 'Analysis Board', 'Recent games']) {
      final button = label == 'Start game'
          ? find.widgetWithText(FilledButton, label)
          : find.widgetWithText(OutlinedButton, label);
      expect(button, findsOneWidget);
      expect(
        button.hitTestable(),
        findsOneWidget,
        reason: '$label rect ${tester.getRect(button)}',
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(52));
    }
    final settings = find.byKey(const ValueKey('home-settings-button'));
    expect(settings.hitTestable(), findsOneWidget);
    expect(tester.getSize(settings).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings separates game, engine, and Chessnut controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Game settings'), findsOneWidget);
    expect(find.text('Engine settings'), findsOneWidget);
    expect(find.text('Chessnut'), findsOneWidget);
    expect(find.byKey(const ValueKey('game-sounds-setting')), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('game-sounds-setting')),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('game-haptics-setting')),
          )
          .value,
      isTrue,
    );
    expect(find.byKey(const ValueKey('premoves-setting')), findsOneWidget);
    expect(find.byKey(const ValueKey('sampling-help')), findsOneWidget);
    expect(find.text('Copy diagnostics'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chessnut-sounds-toggle')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-chessnut-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('chessnut-setup-status')), findsNothing);
    expect(find.text('Play Maia'), findsNothing);
    expect(find.text('Advanced'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Play Maia'), findsOneWidget);
    expect(find.text('Game settings'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home owns the expanded Chessnut connection flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const ValueKey('home-chessnut-toggle'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chessnut-setup-status')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chessnut-connect-button')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Chessnut play supports standard-position, unlimited games only.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chessnut-sounds-toggle')), findsNothing);

    final start = find.widgetWithText(FilledButton, 'Start game');
    await tester.ensureVisible(start);
    expect(start, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact large-text layouts keep all actions reachable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'temperatureV2': 0.5,
      'topPV2': 0.9,
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: const GamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final recent = find.widgetWithText(OutlinedButton, 'Recent games');
    await tester.ensureVisible(recent);
    expect(recent.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pumpAndSettle();
    final diagnostics = find.text('Copy diagnostics');
    await tester.ensureVisible(diagnostics);
    expect(diagnostics.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    final warning = find.byKey(
      const ValueKey('sampling-recommendation-warning'),
    );
    await tester.ensureVisible(warning);
    expect(warning, findsOneWidget);
    final help = find.byKey(const ValueKey('sampling-help'));
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Center this tall paragraph within the dialog's scroll viewport.
    await Scrollable.ensureVisible(
      tester.element(find.textContaining('smallest group of moves')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('smallest group of moves').hitTestable(),
      findsOneWidget,
    );
    final researchLink = find.byKey(const ValueKey('sampling-research-link'));
    await tester.ensureVisible(researchLink);
    expect(researchLink.hitTestable(), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
