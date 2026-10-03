// ignore_for_file: invalid_use_of_visible_for_testing_member
// Optional native CLI qualification; not part of the routine Flutter suite.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CliEngine implements StockfishEngineHandle {
  CliEngine(this.process) {
    output = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
  }
  final Process process;
  late final Stream<String> output;
  final commands = <String>[];
  @override
  Stream<String> get stdout => output;
  @override
  set stdin(String command) {
    commands.add(command);
    process.stdin.writeln(command);
  }

  @override
  Future<void> dispose() async {
    stdin = 'quit';
    await process.exitCode.timeout(const Duration(seconds: 5));
    await process.stdin.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('actual analyzer: all modes, every annotation and full provenance', () async {
    SharedPreferences.setMockInitialValues({});
    final path = Platform.environment['MAIA_STOCKFISH']!;
    final corpus = jsonDecode(
      File(
        Platform.environment['MAIA_CLASSIFICATION_CORPUS'] ??
            'test/fixtures/classification/stockfish18-fast.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final games = (corpus['runs'] as List).cast<Map<String, dynamic>>();
    final game = Platform.environment['MAIA_GAME'] == null
        ? games.first
        : games.firstWhere(
            (g) => g['name'] == Platform.environment['MAIA_GAME'],
          );
    final positions = (game['positions'] as List).cast<String>();
    final moves = (game['moves'] as List).cast<String>();
    final engines = <CliEngine>[];
    final analyzer = StockfishAnalyzer.withFactory(() async {
      final engine = CliEngine(await Process.start(path, []));
      engines.add(engine);
      return engine;
    });
    final runs = <Map<String, Object?>>[];
    try {
      final qualities =
          Platform.environment['MAIA_SEQUENCE']?.split(',').map((name) {
            expect(['fast', 'balanced', 'thorough'], contains(name));
            return GameAnalysisQuality.fromStoredName(name);
          }).toList() ??
          [
            GameAnalysisQuality.fast,
            GameAnalysisQuality.balanced,
            GameAnalysisQuality.thorough,
            GameAnalysisQuality.fast,
          ];
      final scenario = Platform.environment['MAIA_SCENARIO'] ?? 'cold';
      expect(['cold', 'warm', 'fresh-process'], contains(scenario));
      Object? warmSession;
      for (final (runIndex, quality) in qualities.indexed) {
        if (scenario == 'fresh-process' && runIndex > 0) await analyzer.close();
        final scope = MaiaInferenceScope();
        final session = scenario == 'warm'
            ? (warmSession ??= Object())
            : Object();
        final watch = Stopwatch()..start();
        final raw = <StockfishReview>[];
        for (final fen in positions) {
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
        final searchMs = watch.elapsedMilliseconds;
        var materialCache = <String, int>{};
        var provisional = <ClassifiedMove>[];
        {
          final preflight = MoveClassifier.startOffMainIsolate(
            scores: raw,
            positions: positions,
            uciMoves: moves,
            requireReliableComparisons: false,
          );
          provisional = await preflight.result;
          materialCache = Map.of(preflight.materialCache);
          await preflight.terminated;
        }
        final preflightMs = watch.elapsedMilliseconds - searchMs;
        final candidates = MoveClassifier.confirmationPlies(
          scores: raw,
          positions: positions,
          uciMoves: moves,
          classifiedMoves: provisional,
        );
        final scores = await analyzer.confirmAnnotations(
          scores: raw,
          positions: positions,
          uciMoves: moves,
          classifiedMoves: provisional,
          scope: scope,
          isCurrent: () => true,
          quality: quality,
        );
        final confirmedMs = watch.elapsedMilliseconds - searchMs - preflightMs;
        final job = MoveClassifier.startOffMainIsolate(
          scores: scores,
          positions: positions,
          uciMoves: moves,
          materialCache: materialCache,
        );
        final labels = await job.result;
        await job.terminated;
        final traces = <Map<String, Object?>>[];
        MoveClassifier.classify(
          scores: scores,
          positions: positions,
          uciMoves: moves,
          trace: traces.add,
          materialCache: materialCache,
        );
        final result = <String, Object?>{
          'name': game['name'],
          'scenario': scenario,
          'runIndex': runIndex,
          'quality': quality.name,
          'searchMs': searchMs,
          'preflightMs': preflightMs,
          'confirmationMs': confirmedMs,
          'totalMs': watch.elapsedMilliseconds,
          'candidates': candidates,
          'trace': traces,
          'scores': [
            for (final (index, s) in scores.indexed)
              {
                'position': index,
                'fen': positions[index],
                'quality': s.evidence?.quality?.name,
                'complete': s.evidence?.complete,
                'cp': s.evaluation,
                'mate': s.mate,
                'depth': s.evidence?.depth,
                'nodes': s.evidence?.nodes,
                'timeMs': s.evidence?.timeMs,
                'reset': s.evidence?.reset,
                'lines': [
                  for (final l in s.lines)
                    {'cp': l.evaluation, 'mate': l.mate, 'moves': l.moves},
                ],
                'previousLines': [
                  for (final l
                      in s.evidence?.previousLines ?? <StockfishLine>[])
                    {'cp': l.evaluation, 'mate': l.mate, 'moves': l.moves},
                ],
                'annotationConfirmation': s.annotationConfirmation == null
                    ? null
                    : {
                        'before': reviewJson(s.annotationConfirmation!.before),
                        'after': reviewJson(s.annotationConfirmation!.after),
                        'beforePrevious':
                            s.annotationConfirmation!.beforePrevious == null
                            ? null
                            : reviewJson(
                                s.annotationConfirmation!.beforePrevious!,
                              ),
                      },
              },
          ],
          'labels': [
            for (final m in labels)
              {'ply': m.ply, 'label': m.classification.name},
          ],
        };
        runs.add(result);
        // ignore: avoid_print
        print(
          'LIVE ${quality.name}: ${result['labels']} search=${searchMs}ms confirmation=${confirmedMs}ms',
        );
        // Compare the independent EC oracle on these exact achieved scores.
        // Production can withhold an unsupported standout; every other symbol
        // must agree, including blank labels and all error/interesting labels.
        final oracle = await referenceAnnotations(
          scores,
          positions,
          moves,
          (game['material'] as List).cast<int>(),
        );
        final ungated = MoveClassifier.classify(
          scores: scores,
          positions: positions,
          uciMoves: moves,
          materialCache: materialCache,
          requireReliableComparisons: false,
        );
        final ungatedSymbols = symbols(ungated, moves.length);
        expect(ungatedSymbols, oracle, reason: '${quality.name} EC every ply');
        final productionSymbols = symbols(labels, moves.length);
        for (var ply = 0; ply < moves.length; ply++) {
          final actual = productionSymbols[ply];
          final withheld =
              (oracle[ply] == '!' || oracle[ply] == '!!') && actual == '';
          expect(
            actual,
            withheld ? '' : oracle[ply],
            reason: '${quality.name} production ply ${ply + 1}',
          );
        }
        for (final (index, score) in scores.indexed) {
          expect(
            score.evaluation,
            raw[index].evaluation,
            reason: 'graph score $index',
          );
          expect(score.mate, raw[index].mate, reason: 'graph mate $index');
          expect(
            reviewJson(score)['lines'],
            reviewJson(raw[index])['lines'],
            reason: 'baseline PV $index',
          );
          if (score.lines.isEmpty) continue; // terminal positions
          expect(score.evaluation, score.lines.first.evaluation);
          expect(score.mate, score.lines.first.mate);
          expect(score.evidence, isNotNull, reason: 'position $index');
          expect(score.evidence!.quality, quality);
          expect(score.evidence!.depth, greaterThan(0));
        }
        final confirmationOracles = <Map<String, Object?>>[];
        for (final label in labels.where(
          (m) =>
              m.classification == MoveClassification.good ||
              m.classification == MoveClassification.brilliant,
        )) {
          final confirmation = scores[label.ply - 1].annotationConfirmation;
          final window = List<StockfishReview>.of(scores);
          final dependencies = [
            label.ply - 1,
            label.ply,
            if (label.classification == MoveClassification.good &&
                label.ply > 1)
              label.ply - 2,
          ];
          final kind = confirmation == null ? 'prior-iteration' : 'independent';
          for (final position in dependencies) {
            if (confirmation != null) {
              final checked = position == label.ply - 1
                  ? confirmation.before
                  : position == label.ply
                  ? confirmation.after
                  : confirmation.beforePrevious;
              expect(
                checked,
                isNotNull,
                reason: 'confirmation dependency $position',
              );
              window[position] = checked!;
            } else if (scores[position].evidence == null &&
                chess.Chess.fromFEN(positions[position]).game_over) {
              // A terminal result is exact; there is no engine iteration.
              window[position] = scores[position];
            } else {
              final older = scores[position].evidence?.previousLines;
              expect(
                older,
                isNotEmpty,
                reason:
                    '${quality.name} ply ${label.ply} prior dependency $position',
              );
              expect(older!.first.moves, isNotEmpty);
              window[position] = StockfishReview(
                older.first.evaluation,
                older.first.moves.first,
                mate: older.first.mate,
                lines: older,
              );
            }
          }
          final corroboration = await referenceAnnotations(
            window,
            positions,
            moves,
            (game['material'] as List).cast<int>(),
          );
          expect(
            corroboration[label.ply - 1],
            label.classification.symbol,
            reason: '${quality.name} independent confirmation ply ${label.ply}',
          );
          confirmationOracles.add({
            'ply': label.ply,
            'kind': kind,
            'symbol': corroboration[label.ply - 1],
            'dependencies': [
              for (final position in dependencies)
                {
                  'position': position,
                  'fen': positions[position],
                  ...reviewJson(window[position]),
                },
            ],
          });
        }
        result['confirmationOracles'] = confirmationOracles;
        result['oracleAnnotations'] = oracle;
        result['annotations'] = productionSymbols;
        final matching = runs
            .take(runs.length - 1)
            .where((r) => r['quality'] == quality.name)
            .toList();
        final previous = matching.isEmpty ? null : matching.last;
        if (previous != null) {
          final old = previous['annotations'] as List<String>;
          result['changedLabelPlies'] = [
            for (var i = 0; i < old.length; i++)
              if (old[i] != productionSymbols[i]) i + 1,
          ];
        }
      }
    } finally {
      await analyzer.close();
      final output = Platform.environment['MAIA_LIVE_REPORT'];
      if (output != null) {
        File(output).writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
            'engine': path,
            'runs': runs,
            'commands': [for (final e in engines) ...e.commands],
          }),
        );
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

List<String> symbols(List<ClassifiedMove> labels, int count) {
  final result = List.filled(count, '');
  for (final label in labels) {
    result[label.ply - 1] = label.classification.symbol;
  }
  return result;
}

Future<List<String>> referenceAnnotations(
  List<StockfishReview> scores,
  List<String> positions,
  List<String> moves,
  List<int> material,
) async {
  Map<String, Object> value(int cp, int? mate) => {
    'type': mate == null ? 'cp' : 'mate',
    'value': mate ?? cp,
  };
  Map<String, Object> score(StockfishReview s) => value(s.evaluation, s.mate);
  final cases = [
    for (var ply = 1; ply <= moves.length; ply++)
      {
        'prevprev': ply > 1 ? score(scores[ply - 2]) : null,
        'prev': score(scores[ply - 1]),
        'next': score(scores[ply]),
        'color': positions[ply - 1].split(' ')[1] == 'w' ? 'white' : 'black',
        'prevMoves': [
          for (final line in scores[ply - 1].lines)
            {
              'score': {'value': value(line.evaluation, line.mate)},
              'sanMoves': line.moves,
            },
        ],
        'is_sacrifice':
            !chess.Chess.fromFEN(positions[ply]).game_over &&
            material[ply - 1] > -material[ply] + 100,
        'move': moves[ply - 1],
      },
  ];
  final process = await Process.start(
    Platform.environment['MAIA_NODE'] ?? 'node',
    ['tool/hardening/classification/reference/annotate.mjs'],
  );
  final stdout = process.stdout.transform(utf8.decoder).join();
  final stderr = process.stderr.transform(utf8.decoder).join();
  process.stdin.write(jsonEncode(cases));
  await process.stdin.close();
  final exit = await process.exitCode;
  expect(exit, 0, reason: await stderr);
  return (jsonDecode(await stdout) as List).cast<String>();
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
