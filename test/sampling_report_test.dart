import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

Map<String, dynamic> reportRecord({
  String fen = chess.Chess.DEFAULT_POSITION,
  String move = 'e2e4',
  String outcome = 'committed',
  String id = 'one',
}) {
  final board = chess.Chess.fromFEN(fen);
  final moves = board.moves({'asObjects': true}).cast<chess.Move>();
  return {
    'schema': 1,
    'algorithm': 'mobile-maia-sampler-v1',
    'gameId': 'game',
    'requestId': id,
    'fen': fen,
    'selfElo': 1600,
    'historyEnabled': false,
    'startedAt': '2026-10-15T00:00:00Z',
    'outcome': outcome,
    if (outcome == 'committed') 'committedMove': move,
    'sampling': {
      'mode': 'random',
      'selected': move,
      'effectiveTemperature': 1.0,
      'effectiveTopP': 1.0,
      'random': {
        'nucleusCount': moves.length,
        'total': moves.length.toDouble(),
        'weightedOrder': [
          for (final m in moves) {'uci': MaiaEncoding.uci(m), 'weight': 1.0},
        ],
      },
    },
    'rawLegalPolicy': [
      for (final m in moves)
        {'uci': MaiaEncoding.uci(m), 'probability': 1 / moves.length},
    ],
  };
}

String exportText(List<Map<String, dynamic>> records, {int pruned = 0}) {
  final lines = [
    jsonEncode({
      'type': 'manifest',
      'schema': 1,
      'algorithm': 'mobile-maia-sampler-v1',
      'prunedGames': pruned,
      'droppedRecords': 0,
      'storageErrorObserved': false,
    }),
    for (final r in records)
      jsonEncode({
        'record': jsonEncode(r),
        'sha256': sha256.convert(utf8.encode(jsonEncode(r))).toString(),
      }),
  ];
  final body = '${lines.join('\n')}\n';
  return '$body${jsonEncode({'type': 'footer', 'records': records.length, 'contentSha256': sha256.convert(utf8.encode(body)).toString()})}\n';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('maia-report-test');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  Future<SamplingReport> read(String text) async {
    final f = await File('${dir.path}/export.jsonl').writeAsString(text);
    return SamplingReport.read(f);
  }

  test(
    'game result perspective, unknown metadata and safe HTML navigation',
    () async {
      final labels = samplingReportText(
        await AppLocalizations.delegate.load(const Locale('en')),
      );
      for (final white in [true, false]) {
        for (final result in ['1-0', '0-1', '1/2-1/2', '*', 'unknown']) {
          final g = SamplingReportGame({
            'playerIsWhite': white,
            'elo': 1600,
            'result': result,
          }, labels);
          expect(g.white, white ? 'You' : 'Maia 1600');
          expect(g.black, white ? 'Maia 1600' : 'You');
          expect(g.outcome, switch (result) {
            '1-0' => white ? RecentGameOutcome.win : RecentGameOutcome.loss,
            '0-1' => white ? RecentGameOutcome.loss : RecentGameOutcome.win,
            '1/2-1/2' => RecentGameOutcome.draw,
            '*' => RecentGameOutcome.incomplete,
            _ => RecentGameOutcome.unknown,
          });
        }
      }
      final unknown = SamplingReportGame({}, labels);
      expect(unknown.date, '—');
      expect(unknown.outcome, RecentGameOutcome.unknown);
      final report = SamplingReport(
        [SamplingReportDecision.fromJson(reportRecord())],
        incomplete: false,
        summaries: {
          'game': {
            'playerIsWhite': false,
            'result': '0-1',
            'opening': '<script>alert(1)</script>',
            'elo': 1600,
          },
        },
      );
      final file = File('${dir.path}/report.html');
      await writeSamplingReportHtml(report, file, labels, 'en', {});
      final html = await file.readAsString();
      expect(html, contains('href="#game-1"'));
      expect(html, contains('id="game-1"'));
      expect(html, contains('href="#game-list"'));
      expect(html, contains('result-win'));
      expect(html, contains('&lt;script&gt;'));
      expect(html, isNot(contains('<script>')));
      expect(html, contains('0–1'));
    },
  );

  test('notation for both colors, castling, en passant, promotion, check and disambiguation', () {
    for (final example in [
      (chess.Chess.DEFAULT_POSITION, 'g1f3', 'Nf3'),
      (
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        'g8f6',
        'Nf6',
      ),
      ('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', 'e1g1', 'O-O'),
      ('r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1', 'e8c8', 'O-O-O'),
      ('7k/8/8/3pP3/8/8/8/7K w - d6 0 1', 'e5d6', 'exd6'),
      ('7k/P7/8/8/8/8/8/7K w - - 0 1', 'a7a8q', 'a8=Q+'),
      ('7k/8/8/8/8/8/p7/7K b - - 0 1', 'a2a1n', 'a1=N'),
      ('7k/8/8/8/8/8/8/1N1N3K w - - 0 1', 'b1c3', 'Nbc3'),
    ]) {
      final d = SamplingReportDecision.fromJson(
        reportRecord(fen: example.$1, move: example.$2),
      );
      expect(d.played!.san, example.$3);
      expect(d.alternatives, hasLength(3));
      expect(d.alternatives.any((m) => m.uci == d.played!.uci), false);
    }
  });
  test(
    'verifies checksums and retains settings, takebacks and unplayed attempts',
    () async {
      final records = [
        reportRecord(),
        reportRecord(id: 'retry'),
        for (final state in [
          'pending',
          'timeout',
          'cancelled-or-stale',
          'clock-expired',
          'error',
          'invalid-output',
        ])
          reportRecord(id: state, outcome: state),
      ];
      records[1]['sampling'] = {
        'mode': 'argmax',
        'selected': 'e2e4',
        'random': null,
        'effectiveTemperature': 0.0,
        'effectiveTopP': 0.0,
      };
      records[1]['historyEnabled'] = true;
      records[2].remove('sampling');
      records[2].remove('rawLegalPolicy');
      final report = await read(exportText(records, pruned: 1));
      expect(report.games, hasLength(1));
      expect(report.decisions, hasLength(8));
      expect(report.incomplete, true);
      expect(report.decisions[1].temperature, 0);
      expect(report.decisions[1].history, true);
      expect(report.decisions[2].temperature, isNull);
      expect(report.decisions.skip(2).every((d) => d.played == null), true);
      expect(report.decisions.first.played!.probability, closeTo(0.05, 0.0001));
    },
  );
  test(
    'rejects corruption, unsupported schema, truncation and trailing data',
    () async {
      final valid = exportText([reportRecord()]);
      for (final bad in [
        valid.replaceFirst('1600', '1700'),
        valid.replaceFirst('"schema":1', '"schema":2'),
        valid.substring(0, valid.lastIndexOf('{"type":"footer"')),
        '$valid{}\n',
        valid.replaceFirst('"records":1', '"records":0'),
        valid.replaceAll('\n', '\r\n'),
        valid.substring(0, valid.length - 1),
      ]) {
        await expectLater(read(bad), throwsFormatException);
      }
      expect(
        () => SamplingReportDecision.fromJson(
          reportRecord()..['committedMove'] = 'a1a8',
        ),
        throwsFormatException,
      );
      expect(
        () =>
            SamplingReportDecision.fromJson(reportRecord()..['fen'] = 'broken'),
        throwsFormatException,
      );
      final duplicate = reportRecord();
      duplicate['sampling']['random']['weightedOrder'][1] =
          duplicate['sampling']['random']['weightedOrder'][0];
      expect(
        () => SamplingReportDecision.fromJson(duplicate),
        throwsFormatException,
      );
    },
  );
  test(
    'localized HTML is offline, escaped, small, and includes bundled diagrams',
    () async {
      final report = await read(
        exportText([
          reportRecord(),
          reportRecord(outcome: 'pending', id: 'pending'),
        ]),
      );
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      final labels = samplingReportText(strings)
        ..['title'] = '<script>alert("x")</script>';
      final pieces = await samplingPieceImages();
      expect(pieces, hasLength(12));
      final f = File('${dir.path}/report.html');
      await writeSamplingReportHtml(report, f, labels, 'en', pieces);
      final html = await f.readAsString();
      expect(html, contains('&lt;script&gt;'));
      expect(html, isNot(contains('<script>')));
      expect(html, isNot(contains('src="https://')));
      expect(html, isNot(contains('url(https://')));
      expect(html, contains('data:image/webp;base64,'));
      expect(html, contains('Not recorded as played'));
      expect(html, contains('e4'));
      expect(html, isNot(contains('<details>')));
      expect(html, contains('class="ranks"'));
      expect(html, contains('class="files"'));
      expect(html, contains('class="played-arrow"'));
      expect(html, contains('fill="#505050"'));
      expect(html, contains('1 in 20'));
      for (final svg in RegExp(r'<svg.*?</svg>').allMatches(html)) {
        expect(svg.group(0), isNot(contains('%')));
        expect(svg.group(0), isNot(contains('<text')));
      }
      expect(html, contains('CC BY-SA 3.0'));
      expect(html.length, lessThan(150000));
      expect(samplingPercent(0.0061, 'de'), '0,61%');
    },
  );
  test('effective probability uses the actual temperature weights and Top-P crossing move', () {
    final board = chess.Chess();
    final moves = board.moves({'asObjects': true}).cast<chess.Move>();
    final logits = List<double>.filled(4352, -1000);
    for (final pair in [('e2e4', 0.6), ('d2d4', 0.3), ('g1f3', 0.1)]) {
      logits[MaiaEncoding.moveIndex(pair.$1, false)] = log(pair.$2);
    }
    for (final temp in [0.0, 0.5, 1.0]) {
      for (final topP in [0.0, 0.8, 1.0]) {
        Map<String, Object?>? trace;
        final selected = MaiaEncoding.sampleLegalMove(
          board,
          moves,
          logits,
          temperature: temp,
          topP: topP,
          random: Random(42),
          onSample: (v) => trace = v,
        );
        final record = reportRecord(move: MaiaEncoding.uci(selected))
          ..['sampling'] = trace;
        // Raw policy is deliberately unrelated: the report must not use it.
        final d = SamplingReportDecision.fromJson(record);
        final distribution = {
          d.played!.uci: d.played!.probability,
          for (final m in d.alternatives) m.uci: m.probability,
        };
        if (temp == 0 || topP == 0) {
          expect(distribution, {'e2e4': 1.0});
          expect(d.alternatives, isEmpty);
        } else if (topP == 0.8) {
          expect(distribution.length, 2);
          expect(distribution['e2e4'], closeTo(temp == 1 ? 2 / 3 : 0.8, 1e-12));
          expect(distribution['d2d4'], closeTo(temp == 1 ? 1 / 3 : 0.2, 1e-12));
          expect(distribution.containsKey('g1f3'), false);
        } else {
          expect(
            distribution['e2e4'],
            closeTo(temp == 1 ? 0.6 : 36 / 46, 1e-12),
          );
          expect(
            distribution['g1f3'],
            closeTo(temp == 1 ? 0.1 : 1 / 46, 1e-12),
          );
        }
        expect(distribution.values.reduce((a, b) => a + b), closeTo(1, 1e-12));
      }
    }
  });
  test('trace errors never silently fall back to raw policy', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (r) => r.remove('sampling'),
      (r) => r['sampling']['selected'] = 'd2d4',
      (r) => r['sampling']['mode'] = 'unknown',
      (r) => r['sampling']['random']['total'] = 0,
      (r) => r['sampling']['random']['nucleusCount'] = 1,
      (r) => r['sampling']['random']['weightedOrder'][0]['weight'] = double.nan,
      (r) => r['sampling']['random']['weightedOrder'][0]['weight'] = -1,
      (r) => r['sampling']['random']['weightedOrder'][1]['weight'] = 2,
    ]) {
      final r = reportRecord();
      mutate(r);
      expect(() => SamplingReportDecision.fromJson(r), throwsFormatException);
    }
    final incomplete = SamplingReportDecision.fromJson(
      reportRecord(outcome: 'pending')..remove('sampling'),
    );
    expect(incomplete.played, isNull);
    expect(incomplete.mostProbable, isNull);
    expect(incomplete.alternatives, isEmpty);
  });
  test('one-in-X handles localization, certainty and extremely small probabilities', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final s = await AppLocalizations.delegate.load(locale);
      final t = samplingReportText(s);
      final chance = samplingChance('e4', 0.1804, t, s.localeName);
      expect(
        chance,
        contains(
          locale.languageCode == 'en' ||
                  ['ja', 'zh', 'ko', 'hi'].contains(locale.languageCode)
              ? '5.5'
              : '5,5',
        ),
      );
      expect(samplingChance('e4', 1, t, s.localeName), s.samplingCertain('e4'));
      expect(
        samplingChance('e4', 0.99999, t, s.localeName),
        s.samplingAlmostCertain('e4'),
      );
      expect(
        samplingChance('e4', 5e-324, t, s.localeName),
        isNot(contains('Infinity')),
      );
      expect(samplingChance('e4', 5e-324, t, s.localeName), contains('10^323'));
    }
    final t = samplingReportText(
      await AppLocalizations.delegate.load(const Locale('en')),
    );
    expect(samplingChance('e4', 0.5, t, 'en'), contains('1 in 2 '));
    expect(() => samplingChance('e4', 0, t, 'en'), throwsFormatException);
  });
  test('arrows distinguish played and most probable, with ties combined', () {
    final d = SamplingReportDecision.fromJson(reportRecord());
    final board = samplingReportBoard(d);
    expect(RegExp('class="played-arrow"').allMatches(board).length, 1);
    expect(board, isNot(contains('class="probable-arrow"')));
    final r = reportRecord();
    r['sampling']['random']['weightedOrder'][0]['weight'] = 2.0;
    r['sampling']['random']['total'] = 21.0;
    final different = samplingReportBoard(SamplingReportDecision.fromJson(r));
    expect(different, contains('class="probable-arrow"'));
    expect(different, contains('stroke="#737373"'));
    expect(different, isNot(contains('%')));
  });
  // Optional local evidence; no user captures are checked into the repository.
  final source = Platform.environment['MAIA_REPORT_EXPORT_SOURCE'];
  final destination = Platform.environment['MAIA_REPORT_EXPORT_OUTPUT'];
  if (source != null && destination != null) {
    test('render a local capture with the production HTML writer', () async {
      final report = await SamplingReport.read(File(source));
      final images = await samplingPieceImages();
      for (final locale in AppLocalizations.supportedLocales) {
        final strings = await AppLocalizations.delegate.load(locale);
        final target = File('$destination/report-${locale.languageCode}.html');
        await target.parent.create(recursive: true);
        await writeSamplingReportHtml(
          report,
          target,
          samplingReportText(strings),
          strings.localeName,
          images,
        );
      }
    });
  }
  test('large raw payloads are discarded from the compact report', () async {
    final f = File('${dir.path}/large.jsonl');
    final record = reportRecord()
      ..['tokens'] = {'data': List.filled(60000, 'A').join()};
    final content = exportText([
      for (var i = 0; i < 900; i++) {...record, 'requestId': '$i'},
    ]);
    await f.writeAsString(content);
    expect(await f.length(), greaterThan(50 * 1024 * 1024));
    final watch = Stopwatch()..start();
    final report = await SamplingReport.read(f);
    expect(report.decisions, hasLength(900));
    expect(report.decisions.last.alternatives, hasLength(3));
    // Evidence, not a brittle speed assertion on shared CI hosts.
    // ignore: avoid_print
    print(
      'Large report: ${await f.length()} bytes, ${watch.elapsedMilliseconds} ms',
    );
  });
}
