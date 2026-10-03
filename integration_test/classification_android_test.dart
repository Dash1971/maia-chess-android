import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';

import 'fixtures/classification_game.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native Light all modes: every label and per-position provenance', (
    tester,
  ) async {
    final analyzer = StockfishAnalyzer.instance;
    final runs = <Map<String, Object?>>[];
    const sequence = String.fromEnvironment(
      'MAIA_SEQUENCE',
      defaultValue: 'fast,balanced,thorough,fast',
    );
    const freshProcess = bool.fromEnvironment('MAIA_FRESH_PROCESS');
    const warm = bool.fromEnvironment('MAIA_WARM');
    expect(freshProcess && warm, isFalse);
    final warmSession = Object();
    try {
      for (final (runIndex, name) in sequence.split(',').indexed) {
        expect(['fast', 'balanced', 'thorough'], contains(name));
        final quality = GameAnalysisQuality.fromStoredName(name);
        if (freshProcess && runIndex > 0) await analyzer.close();
        final session = warm ? warmSession : Object();
        final scope = MaiaInferenceScope();
        final raw = <StockfishReview>[];
        final watch = Stopwatch()..start();
        for (final fen in classificationPositions) {
          raw.add(
            await analyzer.evaluate(
              fen,
              scope: scope,
              background: true,
              gameAnalysisQuality: quality,
              analysisSession: session,
            ),
          );
        }
        var materialCache = <String, int>{};
        var provisional = <ClassifiedMove>[];
        {
          final preflight = MoveClassifier.startOffMainIsolate(
            scores: raw,
            positions: classificationPositions,
            uciMoves: classificationMoves,
            requireReliableComparisons: false,
          );
          provisional = await preflight.result;
          materialCache = Map.of(preflight.materialCache);
          await preflight.terminated;
        }
        final scores = await analyzer.confirmAnnotations(
          scores: raw,
          positions: classificationPositions,
          uciMoves: classificationMoves,
          classifiedMoves: provisional,
          scope: scope,
          isCurrent: () => true,
          quality: quality,
        );
        final job = MoveClassifier.startOffMainIsolate(
          scores: scores,
          positions: classificationPositions,
          uciMoves: classificationMoves,
          materialCache: materialCache,
        );
        final labels = await job.result;
        await job.terminated;
        // ignore: avoid_print
        print(
          'ANDROID CLASSIFICATION ${quality.name} ${watch.elapsedMilliseconds}ms: ${labels.map((m) => '${m.ply}:${m.classification.name}').join(' ')}',
        );
        for (final score in scores.where((s) => s.lines.isNotEmpty)) {
          expect(score.evaluation, score.lines.first.evaluation);
          expect(score.mate, score.lines.first.mate);
        }
        for (var index = 0; index < scores.length; index++) {
          final score = scores[index];
          expect(score.evaluation, raw[index].evaluation);
          expect(score.mate, raw[index].mate);
          expect(reviewJson(score)['lines'], reviewJson(raw[index])['lines']);
          // ignore: avoid_print
          print(
            'ANDROID SCORE ${quality.name} $index ${jsonEncode({
              'fen': classificationPositions[index],
              'quality': score.evidence?.quality?.name,
              'complete': score.evidence?.complete,
              'reset': score.evidence?.reset,
              'depth': score.evidence?.depth,
              'nodes': score.evidence?.nodes,
              'timeMs': score.evidence?.timeMs,
              'cp': score.evaluation,
              'mate': score.mate,
              'lines': [
                for (final l in score.lines) [l.evaluation, l.mate, l.moves],
              ],
              'previous': [
                for (final l in score.evidence?.previousLines ?? <StockfishLine>[]) [l.evaluation, l.mate, l.moves],
              ],
              'annotationConfirmation': score.annotationConfirmation == null ? null : {'before': reviewJson(score.annotationConfirmation!.before), 'after': reviewJson(score.annotationConfirmation!.after), 'beforePrevious': score.annotationConfirmation!.beforePrevious == null ? null : reviewJson(score.annotationConfirmation!.beforePrevious!)},
            })}',
          );
        }
        final synchronous = MoveClassifier.classify(
          scores: scores,
          positions: classificationPositions,
          uciMoves: classificationMoves,
          materialCache: materialCache,
        );
        List<String> symbols(List<ClassifiedMove> classified) {
          final result = List.filled(classificationMoves.length, '');
          for (final move in classified) {
            result[move.ply - 1] = move.classification.symbol;
          }
          return result;
        }

        final annotations = symbols(labels);
        expect(
          [
            for (var i = 0; i < annotations.length; i++)
              if (annotations[i] == '!!') i + 1,
          ],
          [22, 34, 38],
          reason: '${quality.name}: reported-game regression',
        );
        expect(
          annotations,
          symbols(synchronous),
          reason: '${quality.name}: isolate and synchronous every ply',
        );
        for (final score in scores.where((s) => s.lines.isNotEmpty)) {
          expect(score.evidence, isNotNull);
          expect(score.evidence!.quality, quality);
          expect(score.evidence!.depth, greaterThan(0));
        }
        final matching = runs
            .where((r) => r['quality'] == quality.name)
            .toList();
        final previous = matching.isEmpty ? null : matching.last;
        final report = <String, Object?>{
          'quality': quality.name,
          'runIndex': runIndex,
          'scenario': freshProcess
              ? 'fresh-process'
              : warm
              ? 'warm'
              : 'cold',
          'annotations': annotations,
          'elapsedMs': watch.elapsedMilliseconds,
          if (previous != null)
            'changedLabelPlies': [
              for (var i = 0; i < annotations.length; i++)
                if ((previous['annotations'] as List)[i] != annotations[i])
                  i + 1,
            ],
        };
        runs.add(report);
        // Exhaustive scores above plus this complete symbol list support
        // offline independent EC replay; Android cannot execute Node/Rust.
        // ignore: avoid_print
        print('ANDROID RUN ${jsonEncode(report)}');
      }
    } finally {
      await analyzer.close();
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

Map<String, Object?> reviewJson(StockfishReview s) => {
  'cp': s.evaluation,
  'mate': s.mate,
  'quality': s.evidence?.quality?.name,
  'complete': s.evidence?.complete,
  'depth': s.evidence?.depth,
  'nodes': s.evidence?.nodes,
  'timeMs': s.evidence?.timeMs,
  'reset': s.evidence?.reset,
  'lines': [
    for (final line in s.lines)
      {'cp': line.evaluation, 'mate': line.mate, 'moves': line.moves},
  ],
};
