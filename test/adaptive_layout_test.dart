import 'dart:io';
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';
import 'review_opening_layout_test.dart' show review;

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['MAIA_LAYOUT_CAPTURES'];
  if (directory == null) return;
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void size(WidgetTester tester, Size value) {
  tester.view.physicalSize = value;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    await OpeningNames.load();
    final fonts = Platform.environment['MAIA_FONT_DIR'];
    if (fonts == null) return;
    for (final (family, path) in [
      ('Roboto', '$fonts/Roboto-Regular.ttf'),
      ('MaterialIcons', '$fonts/MaterialIcons-Regular.otf'),
      ('packages/cupertino_icons/CupertinoIcons', '$fonts/CupertinoIcons.ttf'),
      ('LichessIcons', 'assets/fonts/LichessIcons.ttf'),
    ]) {
      await (FontLoader(
        family,
      )..addFont(File(path).readAsBytes().then(ByteData.sublistView))).load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  Widget app(
    Widget home, {
    double scale = 1,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final appearance = AppAppearanceController(readColors: () async => null);
    addTearDown(appearance.dispose);
    return RepaintBoundary(
      child: AppAppearanceSettings(
        controller: appearance,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(const AppAppearance(), Brightness.dark),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              padding: padding,
              viewPadding: padding,
            ),
            child: child!,
          ),
          home: AppLanguageSettings(
            selectedCode: null,
            onChanged: (_) {},
            child: home,
          ),
        ),
      ),
    );
  }

  for (final dimensions in [const Size(844, 390), const Size(1280, 800)]) {
    final name = dimensions.width > 1000 ? 'tablet' : 'phone';
    testWidgets('Home and Settings use real controls in $name columns', (
      tester,
    ) async {
      size(tester, dimensions);
      await tester.pumpWidget(app(const GamePage()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('adaptive-home')), findsOneWidget);
      for (final label in [
        'Start game',
        'Analysis Board',
        'Recent games',
        'Settings',
      ]) {
        final finder = find
            .ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            )
            .first;
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget);
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
        expect(
          tester.getRect(finder).bottom,
          lessThanOrEqualTo(dimensions.height - 8),
        );
      }
      expect(tester.takeException(), isNull);
      await capture(tester, 'home-$name');
      await tester.tap(find.byKey(const ValueKey('home-settings-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('adaptive-settings')), findsOneWidget);
      await tester.tap(
        find.byKey(
          ValueKey(
            'settings-category-${Icons.sports_esports_outlined.codePoint}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('human-timing-setting')),
        findsOneWidget,
      );
      await capture(tester, 'settings-$name');
      await tester.scrollUntilVisible(
        find.byKey(
          ValueKey('settings-category-${Icons.bug_report_outlined.codePoint}'),
        ),
        100,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('settings-categories')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          ValueKey('settings-category-${Icons.bug_report_outlined.codePoint}'),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'settings-diagnostics-$name');
      expect(
        find.byKey(const ValueKey('reset-settings-defaults')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('copy-diagnostics')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeGame(tester);
    });

    testWidgets(
      'live board uses height and survives rotation with a premove on $name',
      (tester) async {
        SharedPreferences.setMockInitialValues({'multiplePremoves': true});
        size(tester, dimensions);
        await ActiveSessionStore.save(
          gameRecord(pgn: '1. e4 *', white: 282000, black: 258000),
        );
        final maia = ControlledMaia();
        await tester.pumpWidget(
          app(
            GamePage(
              maiaEvaluator: maia.call,
              clockFactory: () => TestClock(0),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final finder = find.byKey(const ValueKey('game-board'));
        final controller = boardOf(tester).controller;
        final rect = tester.getRect(finder);
        expect(rect.height, closeTo(dimensions.height - 16, 1));
        expect(rect.bottom, closeTo(dimensions.height - 8, 1));
        await queueMove(tester, 'g1f3');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('premove-queue')), findsOneWidget);
        await capture(tester, 'game-$name');
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(boardOf(tester).controller, same(controller));
        expect(find.byKey(const ValueKey('premove-queue')), findsOneWidget);
        tester.view.physicalSize = dimensions;
        await tester.pumpAndSettle();
        expect(boardOf(tester).controller, same(controller));
        expect(tester.takeException(), isNull);
        await disposeGame(tester);
      },
    );

    testWidgets('Analysis reaches bottom inset with both engines on $name', (
      tester,
    ) async {
      size(tester, dimensions);
      await tester.pumpWidget(RepaintBoundary(child: review(twoEngines: true)));
      await tester.pumpAndSettle();
      final finder = find.byType(cg.Chessboard);
      final controller = tester.widget<cg.Chessboard>(finder).controller;
      expect(tester.getRect(finder).bottom, closeTo(dimensions.height - 8, 1));
      expect(tester.getSize(finder).height, closeTo(dimensions.height - 16, 1));
      expect(
        find.byKey(const ValueKey('next-move-button')).hitTestable(),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('graph-tab')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('graph-tab')).hitTestable(),
        findsOneWidget,
      );
      await capture(tester, 'analysis-$name');
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(tester.widget<cg.Chessboard>(finder).controller, same(controller));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('portrait table keeps compact rows and direct tap / long press', (
    tester,
  ) async {
    // Ahem's wide test glyphs need extra room for measured columns. The
    // real-font phone-width regression lives in recent_games_layout_test.
    size(
      tester,
      Size(Platform.environment['MAIA_FONT_DIR'] == null ? 480 : 360, 800),
    );
    final records = List.generate(
      12,
      (i) => RecentSession('row-$i', DateTime.utc(2026, 11, 15), {
        'type': 'game',
        'playerIsWhite': true,
        'elo': 1600,
        'pgn': '[Date "2026.11.15"]\n[Result "1-0"]\n\n1. e4 1-0',
      }),
    );
    String? opened;
    await tester.pumpWidget(
      app(
        RecentGamesPage(
          loadGames: () async => records,
          openGame: (id) async {
            opened = id;
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recent-table-header')), findsOneWidget);
    final first = find.byKey(const ValueKey('recent-game-row-0'));
    expect(tester.getSize(first).height, inInclusiveRange(48, 56));
    await capture(tester, 'recent-portrait');
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(opened, 'row-0');
    await tester.longPress(first);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byKey(const ValueKey('export-selected-games')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short landscape budgets board padding after Android insets', (
    tester,
  ) async {
    size(tester, const Size(480, 240));
    await ActiveSessionStore.save(
      gameRecord(pgn: '1. e4 *', white: 282000, black: 258000),
    );
    await tester.pumpWidget(
      app(
        GamePage(
          maiaEvaluator: ControlledMaia().call,
          clockFactory: () => TestClock(0),
        ),
        padding: const EdgeInsets.only(top: 28, bottom: 48),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('game-board'))).width,
      greaterThanOrEqualTo(160),
    );
    expect(tester.takeException(), isNull);
    await disposeGame(tester);
  });

  for (final (dimensions, scale) in [
    (const Size(480, 240), 1.0),
    (const Size(400, 240), 2.0),
    (const Size(844, 390), 2.0),
  ]) {
    testWidgets('short landscape $dimensions at $scale keeps board usable', (
      tester,
    ) async {
      size(tester, dimensions);
      await ActiveSessionStore.save(
        gameRecord(pgn: '1. e4 *', white: 282000, black: 258000),
      );
      await tester.pumpWidget(
        app(
          GamePage(
            maiaEvaluator: ControlledMaia().call,
            clockFactory: () => TestClock(0),
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('game-board'))).width,
        greaterThanOrEqualTo(160),
      );
      expect(tester.takeException(), isNull);
      await disposeGame(tester);
    });
  }
}
