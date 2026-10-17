import 'dart:io';
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

const opening =
    'B21 · Sicilian Defense: Smith-Morra Gambit Accepted, Classical Formation';
const pgn =
    '1. e4 c5 2. d4 cxd4 3. c3 dxc3 4. Nxc3 Nc6 5. Nf3 d6 '
    '6. Bc4 a6 7. O-O Nf6 *';
const longestEnglish = (
  name: 'longest-english',
  label: "A29 · English Opening: King's English Variation, Four Knights Variation, Fianchetto Line, with .. d6, Be7",
  pgn: '1. c4 e5 2. Nc3 Nf6 3. g3 Nc6 4. Bg2 d6 5. d3 Be7 6. Nf3 O-O *',
  best: 'c1d2',
  alternative: 'd1d2',
  reply: 'a7a6',
);
const longestLondon = (
  name: 'longest-london',
  label: "D00 · Queen's Pawn Game: Accelerated London System, Steinitz Countergambit, Morris Countergambit Accepted",
  pgn: '1. d4 d5 2. Bf4 c5 3. e4 dxe4 *',
  best: 'd4d5',
  alternative: 'b1c3',
  reply: 'g8f6',
);
const smithMorra = (
  name: 'smith-morra',
  label: opening,
  pgn: pgn,
  best: 'd1e2',
  alternative: 'c1g5',
  reply: 'c8g4',
);
final openingFinder = find.byKey(const ValueKey('review-opening-name'));

Widget review({
  double scale = 1,
  bool twoEngines = false,
  ({
        String name,
        String label,
        String pgn,
        String best,
        String alternative,
        String reply,
      })
      fixture =
      smithMorra,
}) {
  final session = AnalysisSession.fromPgn(fixture.pgn);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff5d735f),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff171a18),
      useMaterial3: true,
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: ReviewPage(
      title: 'Analysis Board',
      positions: session.positions,
      sanMoves: session.sanMoves,
      uciMoves: session.uciMoves,
      initialCurrentFen: session.positions.last,
      playerIsWhite: true,
      pgn: fixture.pgn,
      secondMaiaElo: twoEngines ? 2400 : null,
      onHome: () {},
      // Deterministic display fixtures; this test does not run chess engines.
      evaluator: (_) async => StockfishReview(
        -30,
        fixture.best,
        lines: [
          StockfishLine(evaluation: -30, moves: [fixture.best, fixture.reply]),
          StockfishLine(
            evaluation: -40,
            moves: [fixture.alternative, fixture.reply],
          ),
        ],
      ),
      maiaPolicyEvaluator: (_, _) async {
        final policy = List<double>.filled(4352, -20);
        policy[MaiaEncoding.moveIndex(fixture.best, false)] = 3;
        policy[MaiaEncoding.moveIndex(fixture.alternative, false)] = 2;
        return policy;
      },
    ),
  );
}

void main() {
  setUpAll(OpeningNames.load);

  test('fixtures cover both longest names in the bundled database', () async {
    final rows = (await rootBundle.loadString(
      'assets/openings/lichess_openings.tsv',
    )).trim().split('\n').skip(1).map((line) => line.split('\t')).toList();
    final length = rows
        .map((row) => row[1].length)
        .reduce((a, b) => a > b ? a : b);
    expect(length, 99);
    expect(
      rows
          .where((row) => row[1].length == length)
          .map((row) => '${row[0]} · ${row[1]}')
          .toSet(),
      {longestEnglish.label, longestLondon.label},
    );
  });

  for (final fixture in [smithMorra, longestEnglish, longestLondon]) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        for (final twoEngines in [false, true]) {
          testWidgets(
            '${fixture.name} full opening at $size, scale $scale, two engines $twoEngines',
            (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final semantics = tester.ensureSemantics();
              try {
                await tester.pumpWidget(
                  review(
                    scale: scale,
                    twoEngines: twoEngines,
                    fixture: fixture,
                  ),
                );
                await tester.pumpAndSettle();
                expect(find.text(fixture.label), findsOneWidget);
                final rich = find.descendant(
                  of: openingFinder,
                  matching: find.byType(RichText),
                );
                final paragraph = tester.renderObject<RenderParagraph>(rich);
                final details = find.byKey(
                  const ValueKey('review-opening-details'),
                );
                expect(
                  details,
                  paragraph.didExceedMaxLines ? findsOneWidget : findsNothing,
                );
                expect(tester.getSemantics(openingFinder).label, fixture.label);
                if (paragraph.didExceedMaxLines) {
                  await tester.tap(openingFinder);
                  await tester.pumpAndSettle();
                  final full = find.byKey(
                    const ValueKey('review-opening-full-name'),
                  );
                  expect(full, findsOneWidget);
                  final fullParagraph = tester.renderObject<RenderParagraph>(
                    find.descendant(of: full, matching: find.byType(RichText)),
                  );
                  expect(fullParagraph.didExceedMaxLines, isFalse);
                  final last = fullParagraph.getBoxesForSelection(
                    TextSelection(
                      baseOffset: fixture.label.length - 1,
                      extentOffset: fixture.label.length,
                    ),
                  );
                  expect(last, isNotEmpty);
                  expect(
                    last.last.bottom,
                    lessThanOrEqualTo(fullParagraph.size.height + 0.01),
                  );
                  await tester.tap(find.text('Close'));
                  await tester.pumpAndSettle();
                  expect(find.byType(AlertDialog), findsNothing);
                }
                expect(
                  find.byTooltip('Previous move').hitTestable(),
                  findsOneWidget,
                );
                expect(
                  find.byTooltip('Next move').hitTestable(),
                  findsOneWidget,
                );
                await tester.ensureVisible(
                  find.byKey(const ValueKey('analysis-engine-lines')),
                );
                await tester.ensureVisible(
                  find.byKey(const ValueKey('analysis-tab-panel')),
                );
                expect(
                  tester
                      .getSize(find.byKey(const ValueKey('analysis-tab-panel')))
                      .height,
                  greaterThanOrEqualTo(56),
                );
                expect(
                  find.byTooltip('Previous move').hitTestable(),
                  findsOneWidget,
                );
                expect(tester.takeException(), isNull);
                await tester.pumpWidget(const SizedBox.shrink());
                await tester.pumpAndSettle();
              } finally {
                semantics.dispose();
              }
            },
          );
        }
      }
    }
  }

  testWidgets('opening follows navigation into a new variation and back', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(review());
      await tester.pumpAndSettle();
      expect(find.text(opening), findsOneWidget);
      await tester.longPress(find.byTooltip('Previous move'));
      await tester.pumpAndSettle();
      expect(openingFinder, findsNothing);
      final board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      board.onMove!(dc.NormalMove.fromUci('d2d4'));
      await tester.pumpAndSettle();
      final branchName = OpeningNames.identify(['d2d4'])!;
      expect(find.text(branchName), findsOneWidget);
      expect(tester.getSemantics(openingFinder).label, branchName);
      await tester.tap(find.byTooltip('Previous move'));
      await tester.pumpAndSettle();
      expect(openingFinder, findsNothing);
      await tester.longPress(find.byTooltip('Next move'));
      await tester.pumpAndSettle();
      expect(find.text(opening), findsOneWidget);
      expect(tester.getSemantics(openingFinder).label, opening);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    } finally {
      semantics.dispose();
    }
  });

  final output = Platform.environment['MAIA_OPENING_SCREENSHOTS'];
  if (output != null) {
    testWidgets('capture opening layout for review', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = Platform.environment['MAIA_REPORT_FONT']!;
      final fonts = {
        'Roboto': Future.value(
          ByteData.sublistView(File(font).readAsBytesSync()),
        ),
        'MaterialIcons': rootBundle.load('fonts/MaterialIcons-Regular.otf'),
        'LichessIcons': rootBundle.load('assets/fonts/LichessIcons.ttf'),
        'packages/cupertino_icons/CupertinoIcons': rootBundle.load(
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
        ),
      };
      for (final entry in fonts.entries) {
        final loader = FontLoader(entry.key)..addFont(entry.value);
        await tester.runAsync(loader.load);
      }
      for (final fixture in [smithMorra, longestEnglish, longestLondon]) {
        for (final entry in {
          'portrait': (const Size(390, 844), 1.0),
          'narrow': (const Size(320, 568), 1.0),
          'large-text': (const Size(320, 568), 2.0),
          'landscape': (const Size(844, 390), 1.0),
        }.entries) {
          tester.view.physicalSize = entry.value.$1;
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: review(
                scale: entry.value.$2,
                twoEngines: true,
                fixture: fixture,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: openingFinder, matching: find.byType(RichText)),
          );
          final lines = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: fixture.label.length),
          );
          // Report the compact label with the real font.
          debugPrint(
            '${fixture.name} ${entry.key}: ${lines.length} lines, ${paragraph.size.height}px text',
          );
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(output).create(recursive: true);
            await File('$output/${fixture.name}-${entry.key}.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
          if (find
              .byKey(const ValueKey('review-opening-details'))
              .evaluate()
              .isNotEmpty) {
            await tester.tap(openingFinder);
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('$output/${fixture.name}-${entry.key}-dialog.png')
                  .writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
            await tester.tap(find.text('Close'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    });
  }
}
