import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  BoardPreferencesController controller() =>
      BoardPreferencesController(read: () async => null, write: (_) async {});
  Widget app(
    BoardPreferencesController preferences,
    Widget home, {
    Locale locale = const Locale('en'),
    double scale = 1,
    Brightness brightness = Brightness.dark,
  }) => BoardPreferencesScope(
    controller: preferences,
    child: MaterialApp(
      locale: locale,
      theme: ThemeData(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );

  test(
    'approved catalogue is explicit and unknown or restricted IDs fall back',
    () {
      expect(BoardDesign.values.length, 25);
      expect(PieceDesign.values.length, 16);
      final value = BoardPreferences.decode(
        '{"board":"future","pieces":"california","coordinates":false}',
      );
      expect(value.board, BoardDesign.brown);
      expect(value.pieces, PieceDesign.cburnett);
      expect(value.coordinates, isFalse);
      final choice = value.copyWith(
        board: BoardDesign.wood4,
        pieces: PieceDesign.kiwenSuwi,
      );
      expect(BoardPreferences.decode(choice.encode()).board, BoardDesign.wood4);
      expect(
        BoardPreferences.decode(choice.encode()).pieces,
        PieceDesign.kiwenSuwi,
      );
      expect(
        BoardPreferences.decode('{"coordinates":false}').board,
        BoardDesign.brown,
      );
    },
  );

  testWidgets('every approved piece and board asset is available offline', (
    tester,
  ) async {
    final manifest = jsonDecode(
      File('docs/board-style-assets.json').readAsStringSync(),
    ) as Map;
    final paths = (manifest['files'] as List)
        .cast<Map>()
        .where((f) => (f['path'] as String).startsWith('assets/'))
        .map((f) => f['path'] as String)
        .toSet();
    for (final path in paths) {
      final bytes = await rootBundle.load('packages/chessground/$path');
      expect(bytes.lengthInBytes, greaterThan(0));
    }
    for (final pieces in PieceDesign.values) {
      expect(pieces.assets.length, 12);
      for (final image in pieces.assets.values) {
        expect(paths, contains(image.assetName));
      }
    }
  });

  testWidgets(
    'board and piece selectors preserve each other and expose selected semantics',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = controller();
      addTearDown(prefs.dispose);
      await tester.pumpWidget(
        app(
          prefs,
          const Scaffold(
            body: SingleChildScrollView(child: BoardSettingsSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-design-selector')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('style-board-blue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('style-board-blue')));
      await tester.pumpAndSettle();
      expect(prefs.value.board, BoardDesign.blue);
      expect(prefs.value.pieces, PieceDesign.cburnett);
      final semantics = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('style-board-blue')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      semantics.dispose();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-piece-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('style-pieces-merida')));
      await tester.pumpAndSettle();
      expect(prefs.value.board, BoardDesign.blue);
      expect(prefs.value.pieces, PieceDesign.merida);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Merida'), findsOneWidget);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} selectors fit narrow/landscape at 200% in both themes',
      (tester) async {
        final prefs = controller();
        addTearDown(prefs.dispose);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final size in [const Size(320, 640), const Size(640, 320)]) {
          tester.view.physicalSize = size;
          for (final brightness in Brightness.values) {
            for (final pieces in [false, true]) {
              await tester.pumpWidget(
                app(
                  prefs,
                  BoardStylePicker(pieceSets: pieces),
                  locale: locale,
                  scale: 2,
                  brightness: brightness,
                ),
              );
              await tester.pumpAndSettle();
              await tester.drag(
                find.byType(CustomScrollView),
                const Offset(0, -500),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
        }
      },
    );
  }

  testWidgets('editor and its piece palette follow the same appearance', (
    tester,
  ) async {
    final prefs = controller();
    addTearDown(prefs.dispose);
    await prefs.select(
      const BoardPreferences(
        board: BoardDesign.blue,
        pieces: PieceDesign.chessnut,
        coordinates: false,
      ),
    );
    await tester.pumpWidget(
      app(
        prefs,
        const BoardEditorPage(initialFen: '4k3/8/8/8/8/8/8/4K3 w - - 0 1'),
      ),
    );
    await tester.pumpAndSettle();
    final settings = tester
        .widget<cg.ChessboardEditor>(find.byType(cg.ChessboardEditor))
        .settings;
    expect(settings.colorScheme, cg.ChessboardColorScheme.blue);
    expect(settings.pieceAssets, PieceDesign.chessnut.assets);
    expect(settings.enableCoordinates, isFalse);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('/chessnut/'),
      ),
      findsNWidgets(12),
    );
  });

  testWidgets(
    'switching piece sets bounds decoded renderer images after the repaint',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      cg.ChessgroundImages.instance.clear();
      final prefs = controller();
      addTearDown(prefs.dispose);
      await tester.pumpWidget(
        app(
          prefs,
          Builder(
            builder: (context) => Scaffold(
              body: BoardStylePreview(preferences: boardPreferencesOf(context)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final watch = Stopwatch()..start();
      var peak = 0;
      for (final pieces in PieceDesign.values) {
        await prefs.select(prefs.value.copyWith(pieces: pieces));
        await tester.pumpAndSettle();
        await tester.runAsync(cg.ChessgroundImages.instance.ready);
        await tester.pumpAndSettle();
        final cache = cg.ChessgroundImages.instance;
        expect(
          cache.keys.toSet().difference(pieces.assets.values.toSet()),
          isEmpty,
        );
        final bytes = cache.keys
            .map(cache.get)
            .whereType<ui.Image>()
            .fold<int>(0, (sum, img) => sum + img.width * img.height * 4);
        if (bytes > peak) peak = bytes;
      }
      // ignore: avoid_print -- retained performance evidence from this test.
      print(
        'BOARD_STYLE_LOAD ${PieceDesign.values.length} sets: ${watch.elapsedMilliseconds} ms, peak retained RGBA bytes $peak at widget runner DPR 1',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('textured highlight images survive independent aid changes', (
    tester,
  ) async {
    final prefs = controller();
    addTearDown(prefs.dispose);
    await prefs.select(const BoardPreferences(board: BoardDesign.horsey));
    await tester.pumpWidget(
      app(
        prefs,
        Builder(
          builder: (context) => Scaffold(
            body: BoardStylePreview(preferences: boardPreferencesOf(context)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scheme = BoardDesign.horsey.scheme;
    final cache = cg.ChessgroundImages.instance;
    await tester.runAsync(() => cache.load(scheme.selected.image!));
    await prefs.select(
      prefs.value.copyWith(coordinates: false, legalMoves: false),
    );
    await tester.pumpAndSettle();
    expect(cache.get(scheme.selected.image!), isNotNull);
    expect(cache.get(scheme.lastMove.image!), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
