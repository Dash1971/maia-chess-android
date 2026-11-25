import 'dart:async';
import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const imported =
    '1. e4 \$1 {[%eval 0.22,18] note [%clk 0:05:00]} '
    'e5 \$6 {[%eval -0.33,18]} *';

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 200 && !ready(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(ready(), isTrue);
}

ReviewPage review(
  String pgn,
  Future<StockfishReview> Function(String) evaluate, {
  Key? key,
  String? initialCurrentFen,
  MoveClassificationRunner? classifier,
}) {
  final session = AnalysisSession.fromPgn(pgn);
  return ReviewPage(
    key: key,
    initialCurrentFen: initialCurrentFen,
    positions: session.positions,
    uciMoves: session.uciMoves,
    sanMoves: session.sanMoves,
    playerIsWhite: true,
    pgn: pgn,
    onHome: () {},
    evaluator: evaluate,
    maiaEvaluator: (_, _) async => null,
    classifier: classifier,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    ActiveSessionStore.setTestRepository(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test(
    'absent initial score retains all imported post-move scores and glyphs',
    () {
      final saved = PgnAnalysisAnnotations.read(imported);
      expect(saved.scores, isNull);
      expect(saved.moveScores!.map((s) => s.evaluation), [22, -33]);
      expect(saved.classifications.map((m) => m.classification), [
        MoveClassification.good,
        MoveClassification.dubious,
      ]);
    },
  );
  for (final source in [
    '1. e4 {[%eval 0.2]} e5 *',
    '1. e4 {[%eval bad]} e5 {[%eval 0.1]} *',
    '{[%eval bad]} $imported',
    '1. e4 e5 *',
    '*',
  ]) {
    test(
      'incomplete or explicitly malformed evaluations are not filled: $source',
      () {
        final saved = PgnAnalysisAnnotations.read(source);
        expect(saved.scores, isNull);
        expect(saved.moveScores, isNull);
      },
    );
  }

  for (final blackStart in [false, true]) {
    testWidgets(
      'only the initial position is evaluated; custom black start=$blackStart',
      (tester) async {
        final fen = chess.Chess.DEFAULT_POSITION.replaceFirst(' w ', ' b ');
        final pgn = blackStart
            ? '[SetUp "1"]\n[FEN "$fen"]\n\n1... e5 {[%eval -0.25]} 2. e4 {[%eval #3]} *'
            : imported;
        final requests = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: review(
              pgn,
              (fen) async {
                requests.add(fen);
                return const StockfishReview(-74, '');
              },
              classifier:
                  ({
                    required scores,
                    required positions,
                    required uciMoves,
                  }) async {
                    fail('Restoring annotations must not run classification');
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Computer analysis'));
        await tester.pumpAndSettle();
        final graph = tester.widget<AnalysisGraph>(find.byType(AnalysisGraph));
        expect(requests, [AnalysisSession.fromPgn(pgn).positions.first]);
        expect(graph.scores.first.evaluation, -74);
        expect(graph.scores[1].evaluation, blackStart ? -25 : 22);
        if (blackStart) {
          expect(graph.scores.last.mate, 3);
        } else {
          expect(graph.scores.last.evaluation, -33);
          expect(graph.classifications, hasLength(2));
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'cancelled selected-root work falls back without replacing imported move scores',
    (tester) async {
      final session = AnalysisSession.fromPgn(imported);
      final selected = Completer<StockfishReview>();
      var roots = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: review(imported, (fen) {
            if (fen == session.positions.first) {
              roots++;
              return roots == 1
                  ? selected.future
                  : Future.value(const StockfishReview(53, ''));
            }
            return Future.value(const StockfishReview(999, ''));
          }, initialCurrentFen: session.positions.last),
        ),
      );
      await tester.pump();
      selected.completeError(const AnalysisCancelled());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pumpAndSettle();
      final graph = tester.widget<AnalysisGraph>(find.byType(AnalysisGraph));
      expect(graph.scores.map((s) => s.evaluation), [53, 22, -33]);
      expect(roots, 2);
      expect(graph.classifications, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'background completion is ignored and resume restores the imported graph',
    (tester) async {
      final selected = Completer<StockfishReview>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: review(imported, (_) {
            calls++;
            return selected.future;
          }),
        ),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      selected.complete(const StockfishReview(53, ''));
      await tester.pumpAndSettle();
      expect(find.byType(AnalysisGraph), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pumpAndSettle();
      final graph = tester.widget<AnalysisGraph>(find.byType(AnalysisGraph));
      expect(graph.scores.map((s) => s.evaluation), [53, 22, -33]);
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'late initial evaluation cannot overwrite an explicit full rerun',
    (tester) async {
      final root = Completer<StockfishReview>();
      final start = AnalysisSession.fromPgn(imported).positions.first;
      await tester.pumpWidget(
        MaterialApp(
          home: review(
            imported,
            (fen) => fen == start
                ? root.future
                : Future.value(const StockfishReview(777, '')),
            classifier: ({
              required scores,
              required positions,
              required uciMoves,
            }) async => [],
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
      await tester.pump();
      root.complete(const StockfishReview(-10, ''));
      await waitFor(
        tester,
        () => find.byType(AnalysisGraph).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      final graph = tester.widget<AnalysisGraph>(find.byType(AnalysisGraph));
      expect(graph.scores.map((s) => s.evaluation), [-10, 777, 777]);
      expect(graph.classifications, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('late completion after disposal cannot restore another game', (
    tester,
  ) async {
    final root = Completer<StockfishReview>();
    await tester.pumpWidget(
      MaterialApp(
        home: review(imported, (_) => root.future, key: const ValueKey('old')),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: review(
          '1. d4 d5 *',
          (_) async => const StockfishReview(100, ''),
          key: const ValueKey('new'),
        ),
      ),
    );
    root.complete(const StockfishReview(-10, ''));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Computer analysis'));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisGraph), findsNothing);
    expect(find.byKey(const ValueKey('run-computer-analysis')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'engine off ignores a late initial score; engine on restores it',
    (tester) async {
      final root = Completer<StockfishReview>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: review(imported, (_) {
            calls++;
            return root.future;
          }),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('analysis-engine-toggle')));
      root.complete(const StockfishReview(14, ''));
      await tester.pumpAndSettle();
      expect(find.byType(AnalysisGraph), findsNothing);
      await tester.tap(find.byKey(const ValueKey('analysis-engine-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pumpAndSettle();
      final graph = tester.widget<AnalysisGraph>(find.byType(AnalysisGraph));
      expect(graph.scores.map((s) => s.evaluation), [14, 22, -33]);
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final surface in ['Review', 'Game']) {
    testWidgets(
      '$surface Copy PGN yields before large annotation stripping and preserves source',
      (tester) async {
        final dir = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('maia-copy-worker-'),
        ))!;
        final repo = SessionRepository(dir);
        ActiveSessionStore.setTestRepository(repo);
        addTearDown(() async => dir.delete(recursive: true));
        final pgn = '{${'x' * (2 * 1024 * 1024)} [%eval 0.10]} $imported';
        String? copied;
        var armed = false, yielded = false;
        bool? yieldedBeforeCopy;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.setData') {
                copied = (call.arguments as Map)['text'] as String;
                yieldedBeforeCopy = yielded;
              }
              return null;
            });
        if (surface == 'Game') {
          await tester.runAsync(
            () => repo.save({
              'type': 'game',
              'pgn': pgn,
              'playerIsWhite': true,
              'timePreset': 'unlimited',
              'clockPaused': true,
            }),
          );
        }
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => Listener(
              onPointerUp: (_) {
                if (armed) Timer.run(() => yielded = true);
              },
              child: child,
            ),
            home: surface == 'Review'
                ? review(pgn, (_) async => const StockfishReview(0, ''))
                : const GamePage(),
          ),
        );
        await tester.pumpAndSettle();
        await waitFor(
          tester,
          () => find.byType(PopupMenuButton<String>).evaluate().isNotEmpty,
        );
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('include-analysis-annotations')),
        );
        await tester.pumpAndSettle();
        armed = true;
        await tester.tap(find.text('Copy PGN'));
        await tester.pump();
        await waitFor(tester, () => copied != null);
        expect(
          yieldedBeforeCopy,
          isTrue,
          reason: 'The UI must get a turn before background PGN stripping completes',
        );
        expect(copied, isNot(contains('[%eval')));
        expect(copied, isNot(contains(r'$1')));
        expect(copied, contains('[%clk 0:05:00]'));
        expect(copied, contains('note'));
        expect(copied!.length, greaterThan(2 * 1024 * 1024));
        if (surface == 'Game') {
          final stored = (await tester.runAsync(
            () => SessionRepository(dir).load(),
          ))!;
          expect(stored['pgn'], contains('[%eval'));
        }
        expect(pgn, contains('[%eval'));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
