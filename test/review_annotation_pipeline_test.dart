import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stockfish_failure_test.dart' show FakeStockfish;

const _before =
    'r2q1rk1/pp2ppbp/2p2np1/2Q3B1/n2PP1b1/2N2N2/PP3PPP/3RKB1R w K - 7 12';
const _after =
    'r2q1rk1/pp2ppbp/2p2np1/6B1/n2PP1b1/Q1N2N2/PP3PPP/3RKB1R b K - 8 12';

class _PipelineEngine extends FakeStockfish {
  _PipelineEngine(this.quality);
  final GameAnalysisQuality quality;
  final commands = <String>[];
  bool holdVerification = false;
  bool verificationPending = false;
  bool white = true;
  @override
  set stdin(String command) {
    commands.add(command);

    if (command.startsWith('position fen ')) {
      white = command.contains(' w ');
    }
    if (command == 'stop' && verificationPending) {
      verificationPending = false;
      output.add('bestmove ${white ? 'c5a3' : 'a4c3'}');
      return;
    }
    if (command.startsWith('go ')) {
      final verifying = command == quality.annotationCommand;
      if (verifying && holdVerification) {
        verificationPending = true;
        return;
      }
      final primary = white ? 'c5a3' : 'a4c3';
      final second = white ? 'c5b4' : 'b7b5';
      final depth = verifying ? quality.depth + 2 : quality.depth;
      final currentCp = verifying ? (white ? -190 : 190) : (white ? 300 : -300);
      final secondCp = verifying ? (white ? -200 : 180) : (white ? -10 : -310);
      searchOutput = [
        'info depth ${depth - 1} multipv 1 score cp ${white && !verifying ? 0 : currentCp} pv $primary',
        'info depth ${depth - 1} multipv 2 score cp ${white && !verifying ? -10 : secondCp} pv $second',
        'info depth $depth multipv 1 score cp $currentCp pv $primary',
        'info depth $depth multipv 2 score cp $secondCp pv $second',
        'bestmove $primary',
      ];
    }
    super.stdin = command;
  }
}

Future<void> _wait(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 150; i++) {
    await tester.pump();
    if (ready()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  fail('Production annotation pipeline did not reach expected state');
}

Future<void> _mount(
  WidgetTester tester,
  StockfishAnalyzer analyzer,
  GameAnalysisQuality quality,
) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [maiaRouteObserver],
      home: ReviewPage(
        positions: const [_before, _after],
        uciMoves: const ['c5a3'],
        sanMoves: const ['Qa3'],
        playerIsWhite: true,
        pgn: '*',
        onHome: () {},
        stockfishAnalyzer: analyzer,
        maiaEvaluator: (_, _) async => null,
        gameAnalysisQuality: quality,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Computer analysis'));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
}

void main() {
  setUpAll(OpeningNames.load);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final quality in GameAnalysisQuality.values) {
    testWidgets(
      '${quality.name}: actual Review verifies Qa3 and preserves graph scores',
      (tester) async {
        final engine = _PipelineEngine(quality);
        final analyzer = StockfishAnalyzer.withFactory(engine.create);
        try {
          await _mount(tester, analyzer, quality);

          await _wait(
            tester,
            () =>
                engine.commands
                        .where((c) => c == quality.annotationCommand)
                        .length ==
                    2 &&
                find
                    .byKey(const ValueKey('move-classification-summary'))
                    .evaluate()
                    .isNotEmpty,
          );
          final graph = tester.widget<AnalysisGraph>(
            find.byType(AnalysisGraph),
          );
          expect(graph.scores.map((score) => score.evaluation), [300, 300]);
          expect(graph.classifications, isEmpty);
          expect(
            engine.commands.where((c) => c == quality.stockfishCommand).length,
            greaterThanOrEqualTo(2),
          );
          expect(
            engine.commands.where((c) => c == quality.annotationCommand).length,
            2,
          );
          expect(graph.scores.first.annotationConfirmation, isNotNull);
          expect(
            graph.scores.first.annotationConfirmation!.before.evaluation,
            -190,
          );
          expect(find.textContaining('failed'), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(analyzer.close);
          await engine.output.close();
        }
      },
    );
    testWidgets(
      '${quality.name}: leaving Review during confirmation cancels without stale publication',
      (tester) async {
        final engine = _PipelineEngine(quality)..holdVerification = true;
        final analyzer = StockfishAnalyzer.withFactory(engine.create);
        try {
          await _mount(tester, analyzer, quality);
          await _wait(tester, () => engine.verificationPending);
          final graph = tester.widget<AnalysisGraph>(
            find.byType(AnalysisGraph),
          );
          expect(graph.scores.map((score) => score.evaluation), [300, 300]);
          expect(graph.classifications, isEmpty);
          // Route disposal executes the actual Review lifecycle cancellation.
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Away'))),
          );
          await _wait(tester, () => !engine.verificationPending);
          expect(find.byType(AnalysisGraph), findsNothing);
          expect(find.textContaining('failed'), findsNothing);
          expect(tester.takeException(), isNull);
          engine.holdVerification = false;
          StockfishReview? restarted;
          final restart = analyzer
              .evaluate(
                _before,
                gameAnalysisQuality: quality,
                analysisSession: Object(),
              )
              .then((score) => restarted = score);
          await _wait(tester, () => restarted != null);
          await restart;
          expect(restarted!.evaluation, 300);
          expect(engine.commands, contains('stop'));
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(analyzer.close);
          await engine.output.close();
        }
      },
    );
  }
}
