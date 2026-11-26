import 'dart:async';
import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const game =
    '[Event "Round trip"]\n[White "A"]\n[Black "B"]\n[Result "*"]\n\n'
    '{Opening note} 1. e4 {my note [%clk 0:05:00]} e5 \$14 (1... c5 {Sicilian}) 2. Nf3 Nc6 3. Bc4 Bc5 *';
final marks = [
  for (var i = 0; i < MoveClassification.values.length; i++)
    ClassifiedMove(ply: i + 1, classification: MoveClassification.values[i]),
];
List<StockfishReview> scores(AnalysisSession session) => [
  for (var i = 0; i < session.positions.length; i++)
    StockfishReview(i * 35 - 70, ''),
];
String annotate(String source) {
  final session = AnalysisSession.fromPgn(source);
  return PgnAnalysisAnnotations.write(
    source,
    scores: scores(session),
    positions: session.positions,
    uciMoves: session.uciMoves,
    classifications: marks
        .where((m) => m.ply <= session.uciMoves.length)
        .toList(),
  );
}

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 200 && !ready(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(ready(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    ActiveSessionStore.setTestRepository(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  test('evaluations and all six standard glyphs survive a PGN round trip', () {
    final output = annotate(game);
    final session = AnalysisSession.fromPgn(game);
    final restored = PgnAnalysisAnnotations.read(output);
    expect(
      restored.scores!.map((s) => s.evaluation),
      scores(session).map((s) => s.evaluation),
    );
    expect(
      restored.classifications.map((m) => m.classification),
      MoveClassification.values,
    );
    for (final text in [
      'Opening note',
      'my note',
      '[%clk 0:05:00]',
      'Sicilian',
      r'$14',
    ]) {
      expect(output, contains(text));
    }
    expect(AnalysisSession.fromPgn(output).uciMoves, session.uciMoves);
    expect(annotate(output), output);
  });
  test(
    'reanalyzing replaces scores and quality glyphs without accumulating tags',
    () {
      final first = annotate(game);
      final session = AnalysisSession.fromPgn(first);
      final second = PgnAnalysisAnnotations.write(
        first,
        scores: [
          for (final _ in session.positions) const StockfishReview(123, ''),
        ],
        positions: session.positions,
        uciMoves: session.uciMoves,
        classifications: const [
          ClassifiedMove(ply: 2, classification: MoveClassification.blunder),
        ],
      );
      final restored = PgnAnalysisAnnotations.read(second);
      expect(restored.scores!.every((s) => s.evaluation == 123), isTrue);
      expect(restored.classifications, hasLength(1));
      expect(restored.classifications.single.ply, 2);
      expect(
        RegExp(r'\[%eval').allMatches(second),
        hasLength(session.positions.length),
      );
      expect(second, contains(r'$14'));
    },
  );
  test('analysis-free export retains prose, clocks, variations and positional glyphs', () {
    final output = PgnAnalysisAnnotations.withoutAnalysis(annotate(game));
    expect(output, isNot(contains('[%eval')));
    final pgn = dc.PgnGame.parsePgn(output);
    expect(pgn.moves.mainline().expand((m) => m.nags ?? <int>[]), [14]);
    for (final text in [
      'Opening note',
      'my note',
      '[%clk 0:05:00]',
      'Sicilian',
    ]) {
      expect(output, contains(text));
    }
    expect(
      AnalysisSession.fromPgn(output).uciMoves,
      AnalysisSession.fromPgn(game).uciMoves,
    );
  });
  test(
    'mate-in and terminal mate use White perspective including a Black win',
    () {
      const source = '1. f3 e5 2. g4 Qh4# 0-1';
      final session = AnalysisSession.fromPgn(source);
      final values = [
        const StockfishReview(15, ''),
        const StockfishReview(-50, ''),
        const StockfishReview(-10, ''),
        const StockfishReview(0, '', mate: -1),
        const StockfishReview(0, '', mate: -1),
      ];
      final output = PgnAnalysisAnnotations.write(
        source,
        scores: values,
        positions: session.positions,
        uciMoves: session.uciMoves,
        classifications: const [],
      );
      expect(output, contains('[%eval #-1]'));
      expect(output, contains('[%eval #0]'));
      final restored = PgnAnalysisAnnotations.read(output).scores!;
      expect(restored.last.mate, -1);
      expect(restored[3].mate, -1);
    },
  );
  test('black-to-move setup restores the correct mover for marks', () {
    final fen = chess.Chess.DEFAULT_POSITION.replaceFirst(' w ', ' b ');
    final source = '[SetUp "1"]\n[FEN "$fen"]\n\n1... e5 2. e4 *';
    final restored = PgnAnalysisAnnotations.read(annotate(source));
    expect(restored.classifications.first.whiteMoved, isFalse);
    expect(restored.classifications[1].whiteMoved, isTrue);
    expect(restored.scores, hasLength(3));
  });
  test(
    'missing or malformed evaluations do not prevent loading move symbols',
    () {
      final source = annotate(game)
          .replaceFirst('[%eval -0.70]', '[%eval bad]');
      final restored = PgnAnalysisAnnotations.read(source);
      expect(restored.scores, isNull);
      expect(restored.classifications, hasLength(6));
      expect(PgnAnalysisAnnotations.read('1. e4 e5 *').scores, isNull);
    },
  );
  test('common eval depths and decimal precision are accepted', () {
    const source = '{[%eval +0.25,18]} 1. e4 {[%eval -0.17, 12]} *';
    expect(
      PgnAnalysisAnnotations.read(source).scores!.map((s) => s.evaluation),
      [25, -17],
    );
  });
  test('an unrelated line cannot receive or restore saved annotations', () {
    final other = AnalysisSession.fromPgn('1. d4 d5 *');
    expect(
      () => PgnAnalysisAnnotations.write(
        '1. e4 e5 *',
        scores: scores(other),
        positions: other.positions,
        uciMoves: other.uciMoves,
      ),
      throwsFormatException,
    );
    expect(
      PgnAnalysisAnnotations.read(
        annotate(game),
        uciMoves: other.uciMoves,
      ).scores,
      isNull,
    );
  });
  test('a played prefix retains its graph beside an unplayed continuation', () {
    const source = '1. e4 e5 2. Nf3 Nc6 *';
    final prefix = AnalysisSession.fromPgn('1. e4 e5 *');
    final output = PgnAnalysisAnnotations.write(
      source,
      scores: scores(prefix),
      positions: prefix.positions,
      uciMoves: prefix.uciMoves,
      classifications: const [],
    );
    expect(
      PgnAnalysisAnnotations.read(output, uciMoves: prefix.uciMoves).scores,
      hasLength(3),
    );
    expect(PgnAnalysisAnnotations.read(output).scores, isNull);
  });
  test('annotation growth beyond the existing PGN limit fails without changing the source', () {
    const start = '1. e4 {';
    const end = '} *';
    final source =
        '$start${'x' * (AnalysisSession.maxPgnBytes - start.length - end.length)}$end';
    final session = AnalysisSession.fromPgn(source);
    expect(
      () => PgnAnalysisAnnotations.write(
        source,
        scores: scores(session),
        positions: session.positions,
        uciMoves: session.uciMoves,
      ),
      throwsFormatException,
    );
    expect(source.length, AnalysisSession.maxPgnBytes);
  });
  test('collection export strips each game before applying the combined size limit', () async {
    final annotated = annotate(game);
    final before = Map<String, String>.from({'a': annotated, 'b': annotated});
    final out = await RecentGamesPgn.export(
      ['a', 'b'],
      (id) async => before[id],
      includeAnalysis: false,
    );
    final parsed = await PgnCollection.parse(out);
    expect(parsed.games, hasLength(2));
    expect(out, isNot(contains('[%eval')));
    expect(out, contains('my note'));
    expect(before['a'], annotated);
  });

  testWidgets(
    'completed analysis saves PGN and a fresh Review restores it without a full run',
    (tester) async {
      final session = AnalysisSession.fromPgn(game);
      String? saved;
      var fullCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: session.positions,
            uciMoves: session.uciMoves,
            sanMoves: session.sanMoves,
            playerIsWhite: true,
            pgn: game,
            onHome: () {},
            evaluator: (fen) async {
              fullCalls++;
              return scores(session)[session.positions.indexOf(fen)];
            },
            maiaEvaluator: (_, _) async => null,
            classifier: ({
              required scores,
              required positions,
              required uciMoves,
            }) async => marks,
            onSessionChanged: (fen, flipped, variations, pgn) async =>
                saved = pgn,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
      await waitFor(
        tester,
        () =>
            saved != null &&
            PgnAnalysisAnnotations.read(saved!).classifications.length == 6,
      );
      final originalSaved = saved!;
      expect(fullCalls, session.positions.length);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final reopened = AnalysisSession.fromPgn(originalSaved);
      var reopenCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: reopened.positions,
            uciMoves: reopened.uciMoves,
            sanMoves: reopened.sanMoves,
            playerIsWhite: true,
            pgn: originalSaved,
            onHome: () {},
            evaluator: (_) async {
              reopenCalls++;
              return const StockfishReview(0, '');
            },
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('e4!!'), findsOneWidget);
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pumpAndSettle();
      final graph = tester.widget<AnalysisGraph>(find.byType(AnalysisGraph));
      expect(graph.scores, hasLength(7));
      expect(graph.classifications, hasLength(6));
      expect(reopenCalls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'a completed graph survives while move classification is still pending',
    (tester) async {
      final session = AnalysisSession.fromPgn('1. e4 e5 *');
      String? saved;
      final labels = Completer<List<ClassifiedMove>>();
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: session.positions,
            uciMoves: session.uciMoves,
            sanMoves: session.sanMoves,
            playerIsWhite: true,
            pgn: session.pgn,
            onHome: () {},
            evaluator: (_) async => const StockfishReview(20, ''),
            maiaEvaluator: (_, _) async => null,
            classifier: ({
              required scores,
              required positions,
              required uciMoves,
            }) => labels.future,
            onSessionChanged: (fen, flipped, variations, pgn) async =>
                saved = pgn,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
      await waitFor(
        tester,
        () =>
            saved != null && PgnAnalysisAnnotations.read(saved!).scores != null,
      );
      expect(PgnAnalysisAnnotations.read(saved!).classifications, isEmpty);
      await tester.ensureVisible(
        find.byKey(const ValueKey('cancel-computer-analysis')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('cancel-computer-analysis')));
      await tester.pump();
      final before = saved;
      labels.complete(marks.take(2).toList());
      await tester.pumpAndSettle();
      expect(saved, before);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final surface in ['Analysis Board', 'Game review']) {
    testWidgets(
      '$surface saves annotations in the existing record for reopening and export',
      (tester) async {
        final dir = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('maia-annotated-storage-'),
        ))!;
        final repo = SessionRepository(dir);
        ActiveSessionStore.setTestRepository(repo);
        addTearDown(() async {
          ActiveSessionStore.setTestRepository(null);
          await dir.delete(recursive: true);
        });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
        const original = '1. f3 e5 2. g4 Qh4# 0-1';
        final session = AnalysisSession.fromPgn(original);
        if (surface == 'Game review') {
          await tester.runAsync(
            () => repo.save({
              'type': 'game',
              'pgn': original,
              'recentState': 'completed',
              'playerIsWhite': true,
              'timePreset': 'unlimited',
              'clockPaused': true,
            }),
          );
          await tester.pumpWidget(const MaiaChessApp());
          await waitFor(
            tester,
            () => find
                .widgetWithText(TextButton, 'Analysis Board')
                .evaluate()
                .isNotEmpty,
          );
          await tester.tap(find.widgetWithText(TextButton, 'Analysis Board'));
        } else {
          await tester.pumpWidget(
            MaterialApp(
              home: AnalysisBoardPage(
                initialSession: session,
                maiaElo: 1600,
                evaluator: (_) async => const StockfishReview(0, ''),
                maiaEvaluator: (_, _) async => null,
              ),
            ),
          );
        }
        await waitFor(
          tester,
          () => find.byType(ReviewPage).evaluate().isNotEmpty,
        );
        final output = annotate(original);
        final page = tester.widget<ReviewPage>(find.byType(ReviewPage));
        var committed = false;
        final operation = page
            .onSessionChanged!(
              session.positions.last,
              false,
              PgnVariationExporter.parseTree(output),
              output,
            )
            .then((_) => committed = true);
        await waitFor(tester, () => committed);
        await operation;
        final saved = (await tester.runAsync(
          () => SessionRepository(dir).load(),
        ))!;
        expect((saved['session'] as Map)['pgn'], output);
        if (surface == 'Game review') {
          final activeGame = saved['activeGame'] as Map;
          expect(activeGame['pgn'], contains('[%eval'));
          expect(
            PgnAnalysisAnnotations.read(activeGame['pgn'] as String)
                .classifications,
            isNotEmpty,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.runAsync(repo.startNew);
          final recent = (await tester.runAsync(
            () => SessionRepository(dir).recent(),
          ))!.single;
          final exported = (await tester.runAsync(
            () => SessionRepository(dir).readPgnForExport(recent.id),
          ))!;
          expect(
            PgnAnalysisAnnotations.read(exported).scores,
            hasLength(session.positions.length),
          );
          expect(
            PgnAnalysisAnnotations.read(exported).classifications,
            isNotEmpty,
          );
        } else {
          final restored = AnalysisSession.fromJson(
            Map<String, dynamic>.from(saved['session'] as Map),
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.pumpWidget(
            MaterialApp(
              home: AnalysisBoardPage(
                initialSession: restored,
                maiaElo: 1600,
                evaluator: (_) async => const StockfishReview(0, ''),
                maiaEvaluator: (_, _) async => null,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Computer analysis'));
          await tester.pumpAndSettle();
          expect(
            tester.widget<AnalysisGraph>(find.byType(AnalysisGraph)).scores,
            hasLength(session.positions.length),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  for (final share in [false, true]) {
    testWidgets(
      '${share ? 'Share' : 'Save'} honors Include analysis without changing the stored PGN',
      (tester) async {
        final pgn = annotate(game);
        final session = AnalysisSession.fromPgn(pgn);
        String? sent;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, (call) async {
              if (call.method == (share ? 'sharePgn' : 'savePgnFile')) {
                sent = (call.arguments as Map)['pgn'] as String;
                return true;
              }
              return null;
            });
        await tester.pumpWidget(
          MaterialApp(
            home: ReviewPage(
              positions: session.positions,
              uciMoves: session.uciMoves,
              sanMoves: session.sanMoves,
              playerIsWhite: true,
              pgn: pgn,
              onHome: () {},
              evaluator: (_) async => const StockfishReview(0, ''),
              maiaEvaluator: (_, _) async => null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('include-analysis-annotations')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Save PGN file'), findsOneWidget);
        expect(find.text('Share PGN'), findsOneWidget);
        await tester.tap(find.text(share ? 'Share PGN' : 'Save PGN file'));
        await waitFor(tester, () => sent != null);
        expect(sent, isNot(contains('[%eval')));
        expect(sent, contains('my note'));
        expect(pgn, contains('[%eval'));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final share in [false, true]) {
    for (final include in [false, true]) {
      testWidgets(
        'Recent games ${share ? 'Share' : 'Save'} exports both games with analysis=$include',
        (tester) async {
          final source = annotate(game);
          String? sent;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(maiaEngineChannel, (call) async {
                if (call.method == (share ? 'sharePgn' : 'savePgnFile')) {
                  sent = (call.arguments as Map)['pgn'] as String;
                  return true;
                }
                return null;
              });
          await tester.pumpWidget(
            MaterialApp(
              home: RecentGamesPage(
                loadGames: () async => [
                  for (final id in ['a', 'b'])
                    RecentSession(id, DateTime.utc(2026, 11, 23), {
                      'type': 'game',
                      'pgn': source,
                    }),
                ],
                readPgnForExport: (_) async => source,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.longPress(find.byKey(const ValueKey('recent-game-a')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('recent-game-b')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('export-selected-games')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<CheckboxListTile>(find.byType(CheckboxListTile))
                .value,
            isTrue,
          );
          if (!include) {
            await tester.tap(
              find.byKey(const ValueKey('include-analysis-annotations')),
            );
            await tester.pumpAndSettle();
          }
          await tester.tap(find.text(share ? 'Share PGN' : 'Save PGN file'));
          await waitFor(tester, () => sent != null);
          final exported = dc.PgnGame.parseMultiGamePgn(sent!);
          expect(exported, hasLength(2));
          expect(sent!.contains('[%eval'), include);
          expect(sent, contains('my note'));
          expect(source, contains('[%eval'));
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets(
    'failed persistence reports an error without preventing graph display',
    (tester) async {
      final session = AnalysisSession.fromPgn(game);
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: session.positions,
            uciMoves: session.uciMoves,
            sanMoves: session.sanMoves,
            playerIsWhite: true,
            pgn: game,
            onHome: () {},
            evaluator: (_) async => const StockfishReview(0, ''),
            maiaEvaluator: (_, _) async => null,
            classifier: ({
              required scores,
              required positions,
              required uciMoves,
            }) async => [],
            onSessionChanged: (_, _, _, _) async =>
                throw const FileSystemException('test write failed'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
      await waitFor(
        tester,
        () => find
            .text('Could not save analysis. The game is unchanged.')
            .evaluate()
            .isNotEmpty,
      );
      expect(find.byType(AnalysisGraph), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('export checkbox fits at 320px/200% ${locale.languageCode}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final strings = await AppLocalizations.delegate.load(locale);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            appBar: AppBar(
              actions: [
                PopupMenuButton<bool>(
                  itemBuilder: (_) => [
                    PgnAnalysisExportOption<bool>(
                      initialValue: true,
                      onChanged: (_) {},
                    ),
                    PopupMenuItem(
                      value: false,
                      child: Text(strings.savePgnFile),
                    ),
                    PopupMenuItem(value: true, child: Text(strings.sharePgn)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PopupMenuButton<bool>));
      await tester.pumpAndSettle();
      expect(find.text(strings.includeAnalysisAnnotations), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('include-analysis-annotations')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
