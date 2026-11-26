import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _gesture(WidgetTester tester, String method) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall(
        method,
        method == 'startBackGesture'
            ? <String, dynamic>{
                'touchOffset': <double>[0, 300],
                'progress': 0.0,
                'swipeEdge': 0,
              }
            : null,
      ),
    ),
    (_) {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platformCalls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platformCalls.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(maiaEngineChannel, null);
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const MaiaChessApp());
    await tester.pumpAndSettle();
  }

  void expectAppHandlesBack() {
    expect(
      platformCalls
          .where(
            (call) => call.method == 'SystemNavigator.setFrameworkHandlesBack',
          )
          .last
          .arguments,
      isTrue,
    );
  }

  void expectNoExit() => expect(
    platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
    isEmpty,
  );

  for (final predictive in [false, true]) {
    final mode = predictive ? 'predictive gesture' : 'system Back';
    Future<void> back(WidgetTester tester) async {
      if (predictive) {
        await _gesture(tester, 'startBackGesture');
        await _gesture(tester, 'commitBackGesture');
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
    }

    for (final screen in ['Settings', 'Recent games']) {
      testWidgets('$mode returns from $screen to Home', (tester) async {
        await mount(tester);
        await tester.tap(
          screen == 'Settings'
              ? find.byKey(const ValueKey('home-settings-button'))
              : find.text('Recent games'),
        );
        await tester.pumpAndSettle();
        expectAppHandlesBack();
        await back(tester);
        expect(find.text('Start game'), findsOneWidget);
        expectNoExit();
      });
    }

    for (final finished in [false, true]) {
      testWidgets('$mode from ${finished ? 'completed' : 'unfinished'} game', (
        tester,
      ) async {
        final session = AnalysisSession.fromPgn(
          finished ? '1. f3 e5 2. g4 Qh4# 0-1' : '1. e4 e5 *',
        );
        await ActiveSessionStore.save({
          'type': 'game',
          'pgn': session.pgn,
          'positions': session.positions,
          'uciMoves': session.uciMoves,
          'playerIsWhite': true,
          'timePreset': 'unlimited',
          'clockPaused': true,
        });
        await mount(tester);
        if (finished) {
          expect(
            find.byKey(const ValueKey('game-conclusion-dialog')),
            findsOneWidget,
          );
          // The conclusion is a separate route: Back dismisses it first.
          await back(tester);
        }
        await back(tester);
        expectNoExit();
        if (!finished) {
          expect(find.text('Leave current game?'), findsOneWidget);
          // Cancel the confirmation without leaving the game.
          await back(tester);
          expect(
            find.byKey(const ValueKey('game-home-button')),
            findsOneWidget,
          );
          expect(await ActiveSessionStore.load(), isNotNull);
          await back(tester);
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Start game'), findsOneWidget);
        expect(await ActiveSessionStore.load(), isNull);
        expectNoExit();
      });
    }
  }

  testWidgets('system Back at Home retains Android exit behavior', (
    tester,
  ) async {
    await mount(tester);
    await tester.binding.handlePopRoute();
    expect(
      platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  });
}
