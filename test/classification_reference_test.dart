import 'dart:convert';
import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  final override = Platform.environment['MAIA_CLASSIFICATION_CORPUS'];
  for (final file
      in override == null
          ? [
              'test/fixtures/classification/stockfish18-fast.json',
              'test/fixtures/classification/stockfish18-balanced-thorough.json',
              'test/fixtures/classification/stockfish-light-fast.json',
              'test/fixtures/classification/stockfish-light-balanced-thorough.json',
            ]
          : [override]) {
    group(file, () => verifyCorpus(file));
  }
}

void verifyCorpus(String file) {
  final corpus =
      jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>;
  for (final (index, dynamic item) in (corpus['runs'] as List).indexed) {
    final game = item as Map<String, dynamic>;
    test(
      'reference $index ${game['name']} ${game['quality']}: every move, material and completed PV',
      () {
        final positions = (game['positions'] as List).cast<String>();
        final scores = <StockfishReview>[];
        final productionScores = <StockfishReview>[];
        final watch = Stopwatch()..start();
        for (var i = 0; i < positions.length; i++) {
          final board = chess.Chess.fromFEN(positions[i]);
          final expected = game['scores'][i] as Map<String, dynamic>;
          final parser = StockfishSearchSnapshots(
            legalMoves: board
                .moves({'asObjects': true})
                .cast<chess.Move>()
                .map(MaiaEncoding.uci)
                .toSet(),
          );
          for (final text in expected['raw'] as List) {
            parser.add(text as String);
          }
          final completed = parser.completed;
          final lines =
              completed?.lines
                  .map((line) => line.forWhite(board.turn == chess.Color.BLACK))
                  .toList() ??
              <StockfishLine>[];
          final result = StockfishReview(
            lines.isEmpty ? expected['cp'] as int : lines.first.evaluation,
            lines.isEmpty ? '(none)' : lines.first.moves.first,
            mate: lines.isEmpty ? expected['mate'] as int? : lines.first.mate,
            lines: lines,
          );
          expect(result.evaluation, expected['cp'], reason: 'ply $i');
          expect(result.mate, expected['mate'], reason: 'ply $i');
          expect(
            result.lines.map(
              (line) => [line.evaluation, line.mate, line.moves],
            ),
            (expected['lines'] as List).map(
              (dynamic line) => [line['cp'], line['mate'], line['moves']],
            ),
            reason: 'ply $i',
          );
          scores.add(result);
          productionScores.add(
            StockfishReview(
              result.evaluation,
              result.bestMove,
              mate: result.mate,
              lines: result.lines,
              evidence: completed == null
                  ? null
                  : StockfishSearchEvidence(
                      depth: completed.depth,
                      nodes: completed.nodes,
                      timeMs: completed.timeMs,
                      complete: true,
                      reset: false,
                      quality: GameAnalysisQuality.fromStoredName(
                        game['quality'] as String?,
                      ),
                      previousLines:
                          parser.previous?.lines
                              .map(
                                (l) =>
                                    l.forWhite(board.turn == chess.Color.BLACK),
                              )
                              .toList() ??
                          const [],
                    ),
            ),
          );
          if (!board.game_over) {
            expect(
              MoveClassifier.materialEvaluation(positions[i]),
              game['material'][i],
              reason: 'Rust material at ply $i: ${positions[i]}',
            );
          }
        }
        final traces = <Map<String, Object?>>[];
        final labels = MoveClassifier.classify(
          scores: scores,
          positions: positions,
          uciMoves: (game['moves'] as List).cast<String>(),
          trace: traces.add,
        );
        const symbols = {
          MoveClassification.brilliant: '!!',
          MoveClassification.good: '!',
          MoveClassification.interesting: '!?',
          MoveClassification.dubious: '?!',
          MoveClassification.mistake: '?',
          MoveClassification.blunder: '??',
        };
        final actual = List.filled(positions.length - 1, '');
        for (final label in labels) {
          actual[label.ply - 1] = symbols[label.classification]!;
        }
        expect(actual, game['annotations'], reason: jsonEncode(traces));
        // The raw oracle intentionally has no confidence policy. Also replay
        // real production provenance, ensuring only actual awards can consume
        // the bounded confirmation budget and weak evidence never earns one.
        final moves = (game['moves'] as List).cast<String>();
        final materialCache = <String, int>{};
        final provisional = MoveClassifier.classify(
          scores: productionScores,
          positions: positions,
          uciMoves: moves,
          requireReliableComparisons: false,
          materialCache: materialCache,
        );
        expect(
          provisional.map((m) => [m.ply, m.classification]),
          labels.map((m) => [m.ply, m.classification]),
        );
        final candidates = MoveClassifier.confirmationPlies(
          scores: productionScores,
          positions: positions,
          uciMoves: moves,
          classifiedMoves: provisional,
        );
        for (final ply in candidates) {
          expect(actual[ply - 1], anyOf('!', '!!'));
        }
        final conservative = MoveClassifier.classify(
          scores: productionScores,
          positions: positions,
          uciMoves: moves,
          materialCache: materialCache,
        );
        for (final label in conservative.where(
          (m) =>
              m.classification == MoveClassification.brilliant ||
              m.classification == MoveClassification.good,
        )) {
          expect(
            MoveClassifier.hasReliableAnnotation(
              scores: productionScores,
              positions: positions,
              uciMoves: moves,
              ply: label.ply,
              classification: label.classification,
            ),
            isTrue,
          );
        }
        if (game['name'] == 'byrne-fischer-1956' && game['quality'] == 'fast') {
          expect(
            actual[22],
            isNot('!!'),
            reason: '12.Qa3 must not be Brilliant',
          );
          expect(
            [
              for (var i = 1; i < actual.length; i += 2)
                if (actual[i] == '!!') i + 1,
            ],
            [22, 34, 38],
          );
          expect([
            for (var i = 0; i < actual.length; i += 2)
              if (actual[i] == '!!') i + 1,
          ], isEmpty);
        }
        // Informational host timing, no fragile shared-runner performance assertion.
        // ignore: avoid_print
        print(
          'CLASSIFICATION ${game['name']} ${positions.length} positions: ${watch.elapsedMilliseconds} ms',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}
