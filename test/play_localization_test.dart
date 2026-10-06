import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fixtures/electronic_board.dart';
import 'fixtures/launch_game.dart' show TestClock;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Chessnut state changes language while preserving saved PGN', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, null),
    );
    await ActiveSessionStore.save({
      'type': 'game',
      'recentState': 'incomplete',
      'pgn': '1. e4 e5 2. Nf3 Nc6 *',
      'status':
          'Your move on Chessnut.', // Canonical status from a legacy save.
      'electronicBoard': 'chessnut-go',
      'clockPaused': true,
    });
    final position = chess.Chess()..load_pgn('1. e4 e5 2. Nf3 Nc6 *');
    final board = SimulatedElectronicBoard()..connectFen = position.fen;
    final locale = ValueNotifier(const Locale('ja'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GamePage(electronicBoardTransport: board),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chessnut未接続'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chessnut-inline-reconnect')));
    await tester.pumpAndSettle();
    expect(find.text('Chessnutで指してください。'), findsOneWidget);
    locale.value = const Locale('es');
    await tester.pumpAndSettle();
    expect(find.text('Haz tu jugada en Chessnut.'), findsOneWidget);
    expect(find.text('Chessnutで指してください。'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chessnut-status-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Jugar en la aplicación'));
    await tester.pumpAndSettle();
    final saved = await ActiveSessionStore.load();
    expect(saved!['pgn'], contains('1. e4 e5 2. Nf3 Nc6'));
    expect(saved['status'], 'Your move.');
    expect(saved['statusCode'], 'yourMove');
    expect(saved['pgn'], isNot(contains('Juega')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await board.close();
  });

  testWidgets('open conclusion updates title and actions after locale change', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, null),
    );
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const GamePage(
            startingFen: '7k/8/5KQ1/8/8/8/8/8 w - - 0 1',
            startingSide: PlayerSide.white,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final board = tester.widget<cg.Chessboard>(
      find.byKey(const ValueKey('game-board')),
    );
    board.onMove!(dc.NormalMove.fromUci('g6g7'));
    await tester.pumpAndSettle();
    expect(find.text('White is victorious'), findsOneWidget);
    final before = await ActiveSessionStore.load();
    locale.value = const Locale('es');
    await tester.pumpAndSettle();
    final strings = await AppLocalizations.delegate.load(const Locale('es'));
    expect(find.text(strings.whiteIsVictorious), findsOneWidget);
    expect(find.text(strings.analysisBoard), findsOneWidget);
    expect(find.text(strings.rematch), findsOneWidget);
    expect(find.text('White is victorious'), findsNothing);
    expect(
      find.byKey(const ValueKey('game-conclusion-dialog')),
      findsOneWidget,
    );
    final after = await ActiveSessionStore.load();
    expect(after!['pgn'], before!['pgn']);
    expect(after['statusCode'], before['statusCode']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'clock tenths follow locale without changing saved milliseconds',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, null),
      );
      await ActiveSessionStore.save({
        'type': 'game',
        'recentState': 'incomplete',
        'pgn': '1. e4 e5 *',
        'timePreset': 'blitz',
        'whiteMillis': 9500,
        'blackMillis': 180000,
        'clockPaused': true,
      });
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (context, value, _) => MaterialApp(
            locale: value,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GamePage(clockFactory: () => TestClock(0)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('white-clock'))).data,
        '0:09.5',
      );
      locale.value = const Locale('es');
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('white-clock'))).data,
        '0:09,5',
      );
      expect((await ActiveSessionStore.load())!['whiteMillis'], 9500);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'open About dialog updates paragraphs and links after locale change',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Mobile Maia',
        packageName: 'maia_chess',
        version: '1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, null),
      );
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (context, value, _) => MaterialApp(
            locale: value,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const GamePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('About'));
      await tester.pumpAndSettle();
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(english.aboutPoweredBy), findsOneWidget);
      locale.value = const Locale('es');
      await tester.pumpAndSettle();
      final spanish = await AppLocalizations.delegate.load(const Locale('es'));
      expect(find.byType(AboutDialog), findsOneWidget);
      expect(find.text(spanish.aboutPoweredBy), findsOneWidget);
      expect(find.text(spanish.aboutLicence), findsOneWidget);
      expect(find.text(spanish.maiaProjectSource), findsOneWidget);
      expect(find.text(spanish.mobileMaiaSource), findsOneWidget);
      expect(find.text(english.aboutPoweredBy), findsNothing);
      expect(find.text(english.mobileMaiaSource), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final code in ['ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt']) {
    testWidgets('setup, sampling help and native errors use $code', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, null),
      );
      final board = _PermissionDeniedBoard();
      final strings = await AppLocalizations.delegate.load(Locale(code));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GamePage(electronicBoardTransport: board),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(strings.playMaia), findsOneWidget);
      expect(
        find.text(
          strings.playRatingValue(
            displayNumber(tester.element(find.byType(GamePage)), 1500),
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('home-chessnut-toggle')));
      await tester.pumpAndSettle();
      expect(find.text(strings.chessnutPermissionPending), findsOneWidget);
      expect(find.textContaining('Sensitive raw native error'), findsNothing);
      final settings = find.byKey(const ValueKey('home-settings-button'));
      await tester.ensureVisible(settings);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      final help = find.byKey(const ValueKey('sampling-help'));
      await tester.ensureVisible(help);
      await tester.tap(help);
      await tester.pumpAndSettle();
      expect(find.text(strings.samplingFullRange), findsOneWidget);
      expect(find.text(strings.samplingTopPHelp), findsOneWidget);
      expect(find.text('Temperature and Top-P'), findsNothing);
      await tester.tap(find.text(strings.close));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await board.close();
    });
  }
}

class _PermissionDeniedBoard extends SimulatedElectronicBoard {
  @override
  Future<void> connect() async => throw PlatformException(
    code: 'permission_pending',
    message: 'Sensitive raw native error',
  );
}
