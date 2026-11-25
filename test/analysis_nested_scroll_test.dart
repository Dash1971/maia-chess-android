import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/variation_navigation_game.dart';

void main() {
  final font = Platform.environment['MAIA_REPORT_FONT'];
  setUpAll(() async {
    await OpeningNames.load();
    if (font != null) {
      await (FontLoader(
        'Roboto',
      )..addFont(File(font).readAsBytes().then(ByteData.sublistView))).load();
      for (final entry in {
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'LichessIcons': 'assets/fonts/LichessIcons.ttf',
        'packages/cupertino_icons/CupertinoIcons':
            'packages/cupertino_icons/assets/CupertinoIcons.ttf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
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

  final session = AnalysisSession.fromPgn(variationNavigationPgn);
  Future<void> mount(
    WidgetTester tester,
    Size size, {
    double scale = 1,
    AnalysisSession? replay,
    int initialPly = 2,
    bool editable = false,
    VoidCallback? onEvaluate,
    EdgeInsets padding = const EdgeInsets.only(top: 24, bottom: 16),
  }) async {
    final game = replay ?? session;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scores = MaiaScoreController();
    addTearDown(scores.dispose);
    await scores.select(true);
    await tester.pumpWidget(
      MaiaScoreScope(
        controller: scores,
        child: RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(
              const AppAppearance(pureBlack: true),
              Brightness.dark,
            ),
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
            home: ReviewPage(
              title: 'Analysis Board',
              positions: game.positions,
              uciMoves: game.uciMoves,
              sanMoves: game.sanMoves,
              pgn: game.pgn,
              initialCurrentFen: game.positions[initialPly],
              onSessionChanged: editable ? (_, _, _, _) async {} : null,
              playerIsWhite: true,
              maiaElo: 1600,
              secondMaiaElo: 2600,
              onHome: () {},
              classifier: ({
                required scores,
                required positions,
                required uciMoves,
              }) async => const <ClassifiedMove>[],
              // Display fixtures only; these tests do not run native engines/models.
              evaluator: (_) async {
                onEvaluate?.call();
                return const StockfishReview(
                  30,
                  'g1f3',
                  lines: [
                    StockfishLine(
                      evaluation: 30,
                      moves: ['g1f3', 'b8c6', 'f1b5', 'g8f6'],
                    ),
                    StockfishLine(
                      evaluation: 10,
                      moves: ['b1c3', 'g8f6', 'f1c4', 'b8c6'],
                    ),
                  ],
                );
              },
              maiaInferenceEvaluator: (_, elo) async {
                onEvaluate?.call();
                final policy = List<double>.filled(4352, -20);
                policy[MaiaEncoding.moveIndex('g1f3', false)] = elo == 2600
                    ? 3
                    : 4;
                policy[MaiaEncoding.moveIndex('f1c4', false)] = 2;
                policy[MaiaEncoding.moveIndex('b1c3', false)] = 1;
                return MaiaInferenceResult(
                  Float32List.fromList(policy),
                  outcome: MaiaOutcome.fromLogits([
                    0,
                    0,
                    elo == 1600 ? .25 : .12,
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final output = Platform.environment['MAIA_ANALYSIS_CAPTURES'];
    if (output == null) return;
    // SVG piece decoding completes outside the test clock on the first frame.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Directory(output).create(recursive: true);
      final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary),
      );
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  Finder movesViewport() => find.descendant(
    of: find.byKey(const ValueKey('analysis-move-list')),
    matching: find.byType(SingleChildScrollView),
  );
  ScrollController moveController(WidgetTester tester) =>
      tester.widget<SingleChildScrollView>(movesViewport()).controller!;
  Rect visibleMoveWindow(WidgetTester tester) =>
      tester.getRect(movesViewport());
  Finder headerViewport() =>
      find.byKey(const ValueKey('analysis-header-viewport'));
  double headerOffset(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: headerViewport(),
          matching: find.byType(Scrollable),
        ),
      )
      .position
      .pixels;
  void expectEndpoint(WidgetTester tester, {required bool end}) {
    final expectedFen = end ? session.positions.last : session.positions.first;
    final board = tester
        .widget<cg.Chessboard>(find.byType(cg.Chessboard))
        .controller;
    // Ignore only canonical en-passant serialization differences.
    expect(board.fen.split(' ').take(2), expectedFen.split(' ').take(2));
    final selected = find.byKey(const ValueKey('analysis-selected-move'));
    expect(selected, end ? findsOneWidget : findsNothing);
    if (end) {
      expect(
        find.descendant(
          of: selected,
          matching: find.text(session.sanMoves.last),
        ),
        findsOneWidget,
      );
    }
    final row = tester.getRect(
      find.byKey(
        ValueKey('mainline-move-${end ? session.sanMoves.length - 1 : 0}'),
      ),
    );
    final window = visibleMoveWindow(tester);
    expect(
      row.top,
      greaterThanOrEqualTo(window.top - 1),
      reason: 'Row $row in window $window',
    );
    expect(
      row.bottom,
      lessThanOrEqualTo(window.bottom + 1),
      reason: 'Row $row in window $window',
    );
  }

  for (final (name, size) in [
    ('portrait phone', const Size(393, 873)),
    ('landscape phone', const Size(873, 393)),
    ('portrait tablet', const Size(800, 1280)),
    ('landscape tablet', const Size(1280, 800)),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$name at $scale long-press endpoints reveal and re-reveal the list without rotation',
        (tester) async {
          var evaluations = 0;
          await mount(
            tester,
            size,
            scale: scale,
            onEvaluate: () => evaluations++,
          );
          final next = find.byKey(const ValueKey('next-move-button'));
          final previous = find.byKey(const ValueKey('previous-move-button'));
          if (name == 'portrait phone' && scale == 1) {
            await capture(tester, 'portrait-initial');
          }
          await tester.longPress(next);
          await tester.pumpAndSettle();
          expectEndpoint(tester, end: true);
          if (name == 'portrait phone' && scale == 1) {
            await capture(tester, 'portrait-end');
          }
          final endBoard = tester.element(find.byType(cg.Chessboard));
          final endEvaluations = evaluations;
          // Browse away without selecting a different move.
          moveController(tester).jumpTo(0);
          await tester.pumpAndSettle();
          expect(tester.widget<InkWell>(next).onTap, isNull);
          await tester.longPress(next);
          await tester.pumpAndSettle();
          expectEndpoint(tester, end: true);
          expect(tester.element(find.byType(cg.Chessboard)), same(endBoard));
          expect(
            evaluations,
            endEvaluations,
            reason: 'Repeated hold must not restart engines',
          );
          await tester.longPress(previous);
          await tester.pumpAndSettle();
          expectEndpoint(tester, end: false);
          if (name == 'portrait phone' && scale == 1) {
            await capture(tester, 'portrait-start');
          }
          final startBoard = tester.element(find.byType(cg.Chessboard));
          final startEvaluations = evaluations;
          moveController(tester)
              .jumpTo(moveController(tester).position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(tester.widget<InkWell>(previous).onTap, isNull);
          await tester.longPress(previous);
          await tester.pumpAndSettle();
          expectEndpoint(tester, end: false);
          expect(tester.element(find.byType(cg.Chessboard)), same(startBoard));
          expect(evaluations, startEvaluations);
          // A late score/header rebuild must not undo the explicit reveal.
          final scores = MaiaScoreScope.maybeOf(
            tester.element(find.byType(ReviewPage)),
          )!;
          await scores.select(false);
          await tester.pumpAndSettle();
          expectEndpoint(tester, end: false);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final (name, size) in [
    ('portrait', const Size(393, 873)),
    ('landscape', const Size(873, 393)),
  ]) {
    testWidgets(
      '$name saved game opened at end and graph-tab holds reveal endpoints',
      (tester) async {
        await mount(
          tester,
          size,
          initialPly: session.sanMoves.length,
          editable: true,
        );
        final next = find.byKey(const ValueKey('next-move-button'));
        final previous = find.byKey(const ValueKey('previous-move-button'));
        await tester.longPress(next);
        await tester.pumpAndSettle();
        expectEndpoint(tester, end: true);
        await tester.ensureVisible(find.byKey(const ValueKey('graph-tab')));
        await tester.tap(find.byKey(const ValueKey('graph-tab')));
        await tester.pumpAndSettle();
        await tester.longPress(previous);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('moves-tab')));
        await tester.tap(find.byKey(const ValueKey('moves-tab')));
        await tester.pumpAndSettle();
        expectEndpoint(tester, end: false);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('an empty analysis position keeps endpoint controls disabled', (
    tester,
  ) async {
    await mount(
      tester,
      const Size(393, 873),
      initialPly: 0,
      replay: AnalysisSession.fromFen(session.positions.first),
    );
    for (final key in ['previous-move-button', 'next-move-button']) {
      final control = tester.widget<InkWell>(find.byKey(ValueKey(key)));
      expect(control.onTap, isNull);
      expect(control.onLongPress, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [
    ('phone', const Size(873, 393)),
    ('small-tablet', const Size(1024, 600)),
    ('tablet', const Size(1280, 800)),
    ('tablet-4x3', const Size(1024, 768)),
    ('split-window', const Size(800, 600)),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$name at $scale moves and endpoint holds keep analysis visible',
        (tester) async {
          await mount(tester, size, scale: scale);
          final header = tester.getRect(headerViewport());
          final offset = headerOffset(tester);
          final board = tester.getRect(find.byType(cg.Chessboard));
          final controls = tester.getRect(
            find.byKey(const ValueKey('analysis-controls')),
          );
          expect(header.height, greaterThan(0));
          expect(
            tester
                .getSize(find.byKey(const ValueKey('analysis-tab-panel')))
                .height,
            greaterThanOrEqualTo(56),
          );
          if (font != null && scale == 1) {
            final engine = tester.getRect(
              find.byKey(const ValueKey('analysis-engine-lines')),
            );
            expect(engine.top, greaterThanOrEqualTo(header.top));
            expect(engine.bottom, lessThanOrEqualTo(header.bottom + 1));
            await capture(tester, '$name-initial');
          }
          final window = visibleMoveWindow(tester);
          await tester.dragFrom(window.center, Offset(0, -window.height * .8));
          await tester.pumpAndSettle();
          expect(moveController(tester).offset, greaterThan(0));
          expect(tester.getRect(headerViewport()), header);
          expect(headerOffset(tester), offset);
          expect(tester.getRect(find.byType(cg.Chessboard)), board);
          expect(
            tester.getRect(find.byKey(const ValueKey('analysis-controls'))),
            controls,
          );
          if (font != null &&
              scale == 1 &&
              (name == 'phone' || name == 'tablet-4x3')) {
            await capture(tester, '$name-scrolled');
          }
          await tester.longPress(
            find.byKey(const ValueKey('next-move-button')),
          );
          await tester.pumpAndSettle();
          expectEndpoint(tester, end: true);
          expect(tester.getRect(headerViewport()).top, header.top);
          expect(headerOffset(tester), offset);
          if (font != null &&
              scale == 1 &&
              (name == 'phone' || name == 'tablet-4x3')) {
            await capture(tester, '$name-end');
          }
          await tester.longPress(
            find.byKey(const ValueKey('previous-move-button')),
          );
          await tester.pumpAndSettle();
          expectEndpoint(tester, end: false);
          expect(headerOffset(tester), offset);
          expect(tester.getRect(headerViewport()).top, header.top);
          if (font != null &&
              scale == 1 &&
              (name == 'phone' || name == 'tablet-4x3')) {
            await capture(tester, '$name-start');
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'graph scrolling keeps engine output visible and restores moves',
    (tester) async {
      await mount(tester, const Size(873, 393));
      final header = tester.getRect(headerViewport());
      await tester.longPress(find.byKey(const ValueKey('next-move-button')));
      await tester.pumpAndSettle();
      final before = moveController(tester).offset;
      await tester.tap(find.byKey(const ValueKey('graph-tab')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('analysis-graph-viewport')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(headerViewport()).top, header.top);
      expect(headerOffset(tester), 0);
      await tester.tap(find.byKey(const ValueKey('moves-tab')));
      await tester.pumpAndSettle();
      expect(moveController(tester).offset, closeTo(before, .1));
      expectEndpoint(tester, end: true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('rotation retains visible selection with a fixed engine pane', (
    tester,
  ) async {
    await mount(tester, const Size(393, 873));
    await tester.longPress(find.byKey(const ValueKey('next-move-button')));
    await tester.pumpAndSettle();
    for (final size in [
      const Size(873, 393),
      const Size(800, 1280),
      const Size(1280, 800),
      const Size(393, 873),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expectEndpoint(tester, end: true);
      expect(headerViewport().hitTestable(), findsOneWidget);
      expect(headerOffset(tester), 0);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('very short windows keep move controls reachable', (
    tester,
  ) async {
    await mount(tester, const Size(480, 200));
    await tester.ensureVisible(find.byKey(const ValueKey('next-move-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('next-move-button')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
