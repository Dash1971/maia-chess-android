import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final invalid in [
    500,
    true,
    ['ja'],
    'unsupported',
  ]) {
    testWidgets('invalid language preference $invalid falls back safely', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'appLanguageV1': invalid});
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Start game'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).containsKey('appLanguageV1'),
        isFalse,
      );
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    final code = locale.languageCode;
    testWidgets('$code compact large-text Home and language menu are usable', (
      tester,
    ) async {
      final strings = await AppLocalizations.delegate.load(locale);
      SharedPreferences.setMockInitialValues({'appLanguageV1': code});
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sideControl = find.byType(SegmentedButton<PlayerSide>);
      expect(
        tester.widget<SegmentedButton<PlayerSide>>(sideControl).direction,
        Axis.vertical,
      );
      final randomSide = find.descendant(
        of: sideControl,
        matching: find.text(strings.random),
      );
      await tester.ensureVisible(randomSide);
      await tester.tap(randomSide);
      await tester.pumpAndSettle();
      expect(tester.widget<SegmentedButton<PlayerSide>>(sideControl).selected, {
        PlayerSide.random,
      });
      final button = find.widgetWithText(FilledButton, strings.startGame);
      await tester.ensureVisible(button);
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-settings-button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(ValueKey('app-language-$code')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(strings.systemDefault),
        -100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.systemDefault).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        (await SharedPreferences.getInstance()).containsKey('appLanguageV1'),
        isFalse,
      );
    });
  }

  testWidgets(
    'system language changes are followed until explicitly overridden',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      expect(find.text('対局開始'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')];
      await tester.pumpAndSettle();
      expect(find.text('Iniciar partida'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
      await tester.pumpAndSettle();
      final portuguese = await AppLocalizations.delegate.load(
        const Locale('pt'),
      );
      expect(find.text(portuguese.startGame), findsOneWidget);
      final context = tester.element(find.byType(GamePage));
      expect(MaterialLocalizations.of(context).saveButtonLabel, 'Salvar');
      expect(
        MaterialLocalizations.of(context)
            .formatCompactDate(DateTime(2026, 7, 14)),
        '14/07/2026',
      );
      tester.platformDispatcher.localesTestValue = const [Locale('it', 'IT')];
      await tester.pumpAndSettle();
      expect(find.text('Start game'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('app-language-system')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('日本語').last);
      await tester.pumpAndSettle();
      tester.platformDispatcher.localesTestValue = const [Locale('ko', 'KR')];
      await tester.pumpAndSettle();
      expect(find.text('対局設定'), findsOneWidget);
    },
  );

  testWidgets('system language change preserves a restored game and clocks', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    await ActiveSessionStore.save(
      gameRecord(pgn: '1. e4 e5 *', white: 123000, black: 117000),
    );
    await tester.pumpWidget(const MaiaChessApp());
    await tester.pumpAndSettle();
    final fen = boardOf(tester).controller.fen;
    final saved = await ActiveSessionStore.load();
    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    await tester.pumpAndSettle();
    expect(boardOf(tester).controller.fen, fen);
    expect(find.byTooltip('対局をリセット'), findsOneWidget);
    expect(await ActiveSessionStore.load(), saved);
    expect(tester.takeException(), isNull);
    await disposeGame(tester);
  });
}
