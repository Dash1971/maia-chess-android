part of '../main.dart';

/// A compact projection of capture data: no tensors/logits reach the UI.
class SamplingReport {
  SamplingReport(
    this.decisions, {
    required this.incomplete,
    this.summaries = const {},
  });
  final Map<String, Map<String, dynamic>> summaries;
  final List<SamplingReportDecision> decisions;
  final bool incomplete;

  /// Streaming and checksum-verified. Call on a worker isolate.
  static Future<SamplingReport> read(File file) async {
    if (await file.length() > 70 * 1024 * 1024) {
      throw const FormatException('Sampling export too large');
    }
    final hashes = <crypto.Digest>[];
    final sink = crypto.sha256.startChunkedConversion(
      _SamplingDigestSink(hashes),
    );
    final decisions = <SamplingReportDecision>[];
    final summaries = <String, Map<String, dynamic>>{};
    var header = false;
    var footer = false;
    var incomplete = false;
    await for (final bytes in _samplingReportLines(file)) {
      if (footer) throw const FormatException('Invalid sampling export');
      final line = utf8.decode(bytes);
      final envelope = jsonDecode(line) as Map<String, dynamic>;
      if (!header) {
        if (envelope['type'] != 'manifest' ||
            envelope['schema'] != 1 ||
            envelope['algorithm'] != 'mobile-maia-sampler-v1') {
          throw const FormatException('Unsupported sampling report');
        }
        incomplete =
            envelope['storageErrorObserved'] == true ||
            (envelope['droppedRecords'] as num) > 0 ||
            (envelope['prunedGames'] as num) > 0;
        if (envelope['games'] case final Map games) {
          if (games.length > 10) {
            throw const FormatException('Too many game summaries');
          }
          for (final entry in games.entries) {
            if (entry.key is! String || entry.value is! Map) {
              throw const FormatException('Invalid game summary');
            }
            summaries[entry.key as String] = Map<String, dynamic>.from(
              entry.value as Map,
            );
          }
        }
        header = true;
      } else if (envelope['type'] == 'footer') {
        sink.close();
        if (envelope['records'] != decisions.length ||
            envelope['contentSha256'] != hashes.single.toString()) {
          throw const FormatException('Sampling export checksum mismatch');
        }
        footer = true;
        continue;
      } else {
        final payload = envelope['record'] as String;
        if (crypto.sha256.convert(utf8.encode(payload)).toString() !=
            envelope['sha256']) {
          throw const FormatException('Sampling record checksum mismatch');
        }
        if (decisions.length >= 8192) {
          throw const FormatException('Too many sampling decisions');
        }
        decisions.add(
          SamplingReportDecision.fromJson(
            jsonDecode(payload) as Map<String, dynamic>,
          ),
        );
      }
      sink.add(bytes);
    }
    if (!footer) throw const FormatException('Incomplete sampling export');
    return SamplingReport(
      List.unmodifiable(decisions),
      incomplete: incomplete,
      summaries: Map.unmodifiable(summaries),
    );
  }

  Map<String, List<SamplingReportDecision>> get games {
    final result = <String, List<SamplingReportDecision>>{};
    for (final decision in decisions) {
      (result[decision.gameId] ??= []).add(decision);
    }
    return result;
  }
}

/// Preserve exact bytes for the footer hash, with a bounded line buffer.
Stream<Uint8List> _samplingReportLines(File file) async* {
  final line = BytesBuilder(copy: false);
  await for (final input in file.openRead()) {
    final chunk = input is Uint8List ? input : Uint8List.fromList(input);
    var start = 0;
    for (var i = 0; i < chunk.length; i++) {
      if (chunk[i] != 10) continue;
      line.add(Uint8List.sublistView(chunk, start, i + 1));
      if (line.length > 1024 * 1024) {
        throw const FormatException('Report line too large');
      }
      yield line.takeBytes();
      start = i + 1;
    }
    if (start < chunk.length) line.add(Uint8List.sublistView(chunk, start));
    if (line.length > 1024 * 1024) {
      throw const FormatException('Report line too large');
    }
  }
  if (line.length != 0) throw const FormatException('Unterminated report line');
}

class SamplingReportMove {
  const SamplingReportMove(this.uci, this.san, this.probability);
  final String uci, san;
  final double probability;
}

class SamplingReportDecision {
  SamplingReportDecision({
    required this.gameId,
    required this.requestId,
    required this.fen,
    required this.number,
    required this.white,
    required this.elo,
    required this.history,
    required this.temperature,
    required this.topP,
    required this.played,
    required this.alternatives,
    required this.startedAt,
  });
  final String gameId, requestId, fen;
  final int number, elo;
  final bool white, history;
  final double? temperature, topP;
  final SamplingReportMove? played;
  final List<SamplingReportMove> alternatives;
  final DateTime startedAt;
  SamplingReportMove? get mostProbable {
    final other = alternatives.firstOrNull;
    if (played == null) return other;
    return other == null || played!.probability >= other.probability
        ? played
        : other;
  }

  String get moveNumber => '$number${white ? '.' : '…'}';

  factory SamplingReportDecision.fromJson(Map<String, dynamic> r) {
    if (r['schema'] != 1 || r['algorithm'] != 'mobile-maia-sampler-v1') {
      throw const FormatException('Unsupported decision');
    }
    final fen = r['fen'] as String;
    if (chess.Chess.validate_fen(fen)['valid'] != true) {
      throw const FormatException('Invalid report position');
    }
    final game = chess.Chess.fromFEN(fen);
    final moves = {
      for (final m in game.moves({'asObjects': true}).cast<chess.Move>())
        MaiaEncoding.uci(m): m,
    };
    final trace = r['sampling'] as Map?;
    double? setting(String name) {
      final v = (trace?[name] as num?)?.toDouble();
      if (v != null && (!v.isFinite || v < 0 || v > 1)) {
        throw const FormatException('Invalid sampler setting');
      }
      return v;
    }

    final temperature = setting('effectiveTemperature');
    final topP = setting('effectiveTopP');
    final policy = <String, double>{};
    // Read the actual sampler trace. Never substitute raw model probabilities
    // or rerun inference: settings, tie order and the retained set are recorded.
    if (trace != null) {
      final selected = trace['selected'];
      if (!moves.containsKey(selected) || temperature == null || topP == null) {
        throw const FormatException('Incomplete sampling trace');
      }
      if (trace['mode'] == 'argmax') {
        if (temperature != 0 || trace['random'] != null) {
          throw const FormatException('Invalid deterministic trace');
        }
        policy[selected as String] = 1;
      } else if (trace['mode'] == 'random') {
        if (temperature <= 0) {
          throw const FormatException('Invalid random temperature');
        }
        final random = trace['random'] as Map;
        final ordered = random['weightedOrder'] as List;
        final count = random['nucleusCount'] as int;
        if (count < 1 ||
            count > ordered.length ||
            ordered.length != moves.length) {
          throw const FormatException('Invalid retained moves');
        }
        final weights = <String, double>{};
        var last = double.infinity;
        for (final item in ordered) {
          final uci = item['uci'] as String;
          final weight = (item['weight'] as num).toDouble();
          if (!moves.containsKey(uci) ||
              weights.containsKey(uci) ||
              !weight.isFinite ||
              weight < 0 ||
              weight > last) {
            throw const FormatException('Invalid sampler weights');
          }
          weights[uci] = weight;
          last = weight;
        }
        final total = weights.values.fold(0.0, (a, b) => a + b);
        if (!total.isFinite || total <= 0) {
          throw const FormatException('Empty sampler distribution');
        }
        var mass = 0.0;
        var expectedCount = 0;
        for (final weight in weights.values) {
          mass += weight / total;
          expectedCount++;
          if (topP < 1 && mass >= topP) break;
        }
        final retained = weights.entries.take(count).toList();
        final retainedTotal = retained.fold(0.0, (v, m) => v + m.value);
        final recordedTotal = (random['total'] as num).toDouble();
        if (count != expectedCount ||
            !recordedTotal.isFinite ||
            retainedTotal <= 0 ||
            (retainedTotal - recordedTotal).abs() > retainedTotal * 1e-12) {
          throw const FormatException('Inconsistent sampling nucleus');
        }
        for (final item in retained) {
          // Zero weights and Top-P-excluded moves are not possible alternatives.
          if (item.value > 0) policy[item.key] = item.value / retainedTotal;
        }
        if (!policy.containsKey(selected)) {
          throw const FormatException(
            'Selected move outside sampling distribution',
          );
        }
      } else {
        throw const FormatException('Unsupported sampler mode');
      }
    }
    SamplingReportMove describe(String uci) =>
        SamplingReportMove(uci, game.move_to_san(moves[uci]!), policy[uci]!);
    final committed = r['outcome'] == 'committed';
    final chosen = r['committedMove'] as String?;
    if (committed &&
        (chosen == null ||
            !policy.containsKey(chosen) ||
            chosen != trace?['selected'])) {
      throw const FormatException('Played move missing from sampling trace');
    }
    // The sampler's recorded ordering breaks ties; a played tied maximum can
    // also be described as most probable, without inventing another preference.
    final order = policy.keys.toList();
    final ranked = [...order]
      ..sort((a, b) {
        final result = policy[b]!.compareTo(policy[a]!);
        return result == 0
            ? order.indexOf(a).compareTo(order.indexOf(b))
            : result;
      });
    final fields = fen.split(' ');
    return SamplingReportDecision(
      gameId: r['gameId'] as String,
      requestId: r['requestId'] as String,
      fen: fen,
      number: int.parse(fields[5]),
      white: fields[1] == 'w',
      elo: r['selfElo'] as int,
      history: r['historyEnabled'] as bool,
      temperature: temperature,
      topP: topP,
      startedAt: DateTime.parse(r['startedAt'] as String).toUtc(),
      played: committed ? describe(chosen!) : null,
      alternatives: ranked
          .where((u) => !committed || u != chosen)
          .take(3)
          .map(describe)
          .toList(growable: false),
    );
  }
}

/// Plain strings only: safe to send to the report-generation isolate.
Map<String, String> samplingReportText(AppLocalizations s) => {
  'retention': s.samplingReportRetention,
  'jump': s.samplingJumpToGame,
  'back': s.samplingBackToGames,
  'win': s.samplingWin,
  'loss': s.samplingLoss,
  'draw': s.samplingDraw,
  'incomplete': s.samplingIncomplete,
  'unknownResult': s.samplingUnknownResult,
  'openingUnknown': s.samplingOpeningUnknown,
  'timeUnknown': s.samplingTimeUnknown,
  'player': s.you,
  'unlimited': s.unlimited,
  'title': s.samplingSummary,
  'explanation': s.samplingReportExplanation,
  'partial': s.samplingReportPartial,
  'missing': s.samplingReportMissing,
  'played': s.samplingPlayed,
  'notPlayed': s.samplingNotPlayed,
  'alternatives': s.samplingAlternatives,
  'mostProbable': s.samplingMostProbable,
  'matched': s.samplingPlayedMostProbable,
  'chance': s.samplingChance('{move}', '{odds}'),
  'certain': s.samplingCertain('{move}'),
  'almostCertain': s.samplingAlmostCertain('{move}'),
  'white': s.white,
  'black': s.black,
  'temperature': s.temperature,
  'topP': s.topP,
  'historyOn': s.maiaHistoryOn,
  'historyOff': s.maiaHistoryOff,
  'game': s.samplingGame('{number}'),
  'records': s.samplingRecords('{count}'),
};

String samplingPercent(double p, String locale) => p > 0 && p < 0.0001
    ? '<${NumberFormat('0.##', locale).format(0.01)}%'
    : '${NumberFormat('0.##', locale).format(p * 100)}%';

String samplingSettings(
  SamplingReportDecision d,
  Map<String, String> t,
  String locale,
) {
  String n(double? v) =>
      v == null ? '—' : NumberFormat('0.##', locale).format(v);
  return 'Maia ${d.elo} · ${d.white ? t['white'] : t['black']}\n'
      '${t['temperature']}: ${n(d.temperature)} · ${t['topP']}: ${n(d.topP)}\n'
      '${d.history ? t['historyOn'] : t['historyOff']}';
}

Future<Map<String, String>> samplingPieceImages() async {
  final images = <String, String>{};
  for (final entry in cg.PieceSet.cburnettAssets.entries) {
    final image = entry.value;
    final bytes = await rootBundle.load(image.keyName);
    images[dc.Piece(
      color: entry.key.side,
      role: entry.key.role,
    ).fenChar] = base64Encode(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }
  return images;
}

/// Human-readable reciprocal of the effective selection probability.
String samplingChance(
  String move,
  double probability,
  Map<String, String> text,
  String locale,
) {
  if (!probability.isFinite || probability <= 0 || probability > 1) {
    throw const FormatException('Invalid selection probability');
  }
  if (probability == 1) return text['certain']!.replaceAll('{move}', move);
  // Do not round a non-certain event into “1 in 1”.
  if (probability > 1 / 1.05) {
    return text['almostCertain']!.replaceAll('{move}', move);
  }
  final inverse = 1 / probability;
  final String odds;
  if (inverse <= 1000000) {
    odds = NumberFormat('#,##0.#', locale).format(inverse);
  } else {
    // Computing the reciprocal directly can overflow for subnormal weights.
    final logInverse = -log(probability) / ln10;
    var exponent = logInverse.floor();
    var mantissa = pow(10, logInverse - exponent).toDouble();
    if (mantissa >= 9.95) {
      mantissa = 1;
      exponent++;
    }
    odds = '${NumberFormat('0.#', locale).format(mantissa)} × 10^$exponent';
  }
  return text['chance']!.replaceAll('{odds}', odds).replaceAll('{move}', move);
}

/// Charcoal is the committed move; gray is a hypothetical most probable move.
/// A tied played maximum needs only one solid arrow. Coordinates are outside.
String samplingReportBoard(SamplingReportDecision d) {
  const escape = HtmlEscape();
  final out = StringBuffer(
    '<div class="diagram"><div class="ranks" aria-hidden="true">',
  );
  for (var rank = 8; rank >= 1; rank--) {
    out.write('<span>$rank</span>');
  }
  out.write(
    '</div><div class="board" role="img" aria-label="${escape.convert(d.fen)}">',
  );
  final squares = <String>[];
  for (final ch in d.fen.split(' ').first.replaceAll('/', '').split('')) {
    final count = int.tryParse(ch);
    if (count != null) {
      squares.addAll(List.filled(count, ''));
    } else {
      squares.add(ch);
    }
  }
  for (var i = 0; i < squares.length; i++) {
    final piece = squares[i];
    out.write(
      '<span class="square ${(i ~/ 8 + i % 8).isOdd ? 'dark' : ''} ${piece.isEmpty ? '' : 'p${piece.codeUnitAt(0)}'}"></span>',
    );
  }
  String arrow(SamplingReportMove move, bool solid) {
    (double, double) point(String s) =>
        ((s.codeUnitAt(0) - 97 + 0.5) * 40, (8 - int.parse(s[1]) + 0.5) * 40);
    final (x, y) = point(move.uci.substring(0, 2));
    final (tx, ty) = point(move.uci.substring(2, 4));
    final length = sqrt(pow(tx - x, 2) + pow(ty - y, 2));
    final ux = (tx - x) / length, uy = (ty - y) / length;
    final sx = x + ux * 12, sy = y + uy * 12;
    final bx = tx - ux * 16, by = ty - uy * 16;
    String q(double x, double y, double n) =>
        '${(x - uy * n).toStringAsFixed(3)},${(y + ux * n).toStringAsFixed(3)}';
    if (solid) {
      return '<path class="played-arrow" d="M ${q(sx, sy, 4)} L ${q(bx, by, 4)} L ${q(bx, by, 9)} L $tx,$ty L ${q(bx, by, -9)} L ${q(bx, by, -4)} L ${q(sx, sy, -4)} Z" fill="#505050"/>';
    }
    return '<path class="probable-arrow" d="M $sx,$sy L $tx,$ty M ${q(bx, by, 9)} L $tx,$ty L ${q(bx, by, -9)}" fill="none" stroke="#737373" stroke-width="3" stroke-linejoin="round"/>';
  }

  out.write('<svg viewBox="0 0 320 320" aria-hidden="true">');
  final top = d.mostProbable;
  if (top != null && top.uci != d.played?.uci) out.write(arrow(top, false));
  if (d.played != null) out.write(arrow(d.played!, true));
  out.write('</svg></div><div class="files" aria-hidden="true">');
  for (final file in 'abcdefgh'.split('')) {
    out.write('<span>$file</span>');
  }
  out.write('</div></div>');
  return out.toString();
}

/// Metadata is a snapshot, separate from immutable individual decisions.
/// Missing fields stay unknown rather than deriving a result from the last FEN.
class SamplingReportGame {
  SamplingReportGame(this.summary, this.text);
  final Map<String, dynamic> summary;
  final Map<String, String> text;
  String get white => _player(true);
  String get black => _player(false);
  String _player(bool white) {
    if (summary['playerIsWhite'] is! bool) return '—';
    if (summary['playerIsWhite'] == white) return text['player']!;
    return summary['elo'] is int ? 'Maia ${summary['elo']}' : 'Maia';
  }

  String get opening =>
      summary['opening'] is String && (summary['opening'] as String).isNotEmpty
      ? summary['opening'] as String
      : text['openingUnknown']!;
  String get timeControl => summary['timeControl'] == '-'
      ? text['unlimited']!
      : summary['timeControl'] is String
      ? summary['timeControl'] as String
      : text['timeUnknown']!;
  RecentGameOutcome get outcome => switch (summary['result']) {
    '*' => RecentGameOutcome.incomplete,
    '1/2-1/2' => RecentGameOutcome.draw,
    '1-0' => switch (summary['playerIsWhite']) {
      true => RecentGameOutcome.win,
      false => RecentGameOutcome.loss,
      _ => RecentGameOutcome.unknown,
    },
    '0-1' => switch (summary['playerIsWhite']) {
      false => RecentGameOutcome.win,
      true => RecentGameOutcome.loss,
      _ => RecentGameOutcome.unknown,
    },
    _ => RecentGameOutcome.unknown,
  };
  String get result {
    final label = switch (outcome) {
      RecentGameOutcome.win => text['win']!,
      RecentGameOutcome.loss => text['loss']!,
      RecentGameOutcome.draw => text['draw']!,
      RecentGameOutcome.incomplete => text['incomplete']!,
      RecentGameOutcome.unknown => text['unknownResult']!,
    };
    final score = switch (summary['result']) {
      '1-0' => '1–0',
      '0-1' => '0–1',
      '1/2-1/2' => '½–½',
      _ => null,
    };
    return score == null ? label : '$score · $label';
  }

  String get date {
    final raw = summary['startedAt'];
    final date = raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
    if (date == null) return '—';
    final offset = date.timeZoneOffset.inMinutes;
    String two(int n) => n.toString().padLeft(2, '0');
    final zone = offset == 0
        ? 'UTC'
        : 'UTC${offset < 0 ? '-' : '+'}${two(offset.abs() ~/ 60)}:${two(offset.abs() % 60)}';
    return '${date.year}-${two(date.month)}-${two(date.day)} · ${two(date.hour)}:${two(date.minute)} $zone';
  }
}

/// Self-contained HTML: bundled pieces, inline vector arrows, no network or JS.
Future<void> writeSamplingReportHtml(
  SamplingReport report,
  File target,
  Map<String, String> text,
  String locale,
  Map<String, String> pieceImages,
) async {
  const escape = HtmlEscape();
  String e(String value) => escape.convert(value);
  String t(String key) => e(text[key]!);
  final out = target.openWrite();
  try {
    out.write('''<!doctype html><html lang="${e(locale)}"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
<title>${t('title')}</title><style>
:root{color-scheme:dark}body{font:16px/1.5 system-ui,sans-serif;max-width:1080px;margin:auto;padding:24px;background:#171e16;color:#e0e8df}h1{font-size:28px}h2{font-size:22px;margin-top:36px}h3{font-size:21px;margin:0 0 12px}small,.muted{color:#bbc9b8}article{display:grid;grid-template-columns:minmax(0,1fr) 340px;gap:28px;align-items:center;padding:24px;margin:12px 0;background:#253026;border-radius:12px}.copy{min-width:0;overflow-wrap:anywhere}.settings{white-space:pre-line;font-size:14px}.alternatives{margin:16px 0;font-size:14px}.option{display:inline-block;margin-right:16px}.legend{margin:16px 0 8px}.legend p{margin:4px 0}.key{display:inline-block;width:18px;height:3px;margin:0 8px 3px 0}.played-key{background:#505050;outline:1px solid #9aa498}.probable-key{background:#737373}.chance{margin:12px 0}.diagram{width:340px;max-width:100%;display:grid;grid-template-columns:20px minmax(0,1fr);grid-template-rows:1fr 20px}.board{position:relative;display:grid;grid-template-columns:repeat(8,1fr);aspect-ratio:1}.square{background:#f0d9b5;background-size:contain}.dark{background-color:#b58863}.board svg{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}.ranks{display:grid;grid-template-rows:repeat(8,1fr);font-size:11px;text-align:center;color:#bbc9b8}.ranks span{align-self:center}.files{grid-column:2;display:grid;grid-template-columns:repeat(8,1fr);font-size:11px;text-align:center;color:#bbc9b8;padding-top:3px}.note{border-left:3px solid #a7dca4;padding-left:12px;font-size:14px}footer{font-size:12px;margin-top:24px}a{color:#a7dca4}@media(max-width:680px){body{padding:16px}article{grid-template-columns:1fr;padding:16px;gap:18px}.diagram{justify-self:center;width:min(100%,340px)}h1{font-size:26px}}@media print{body{background:white;color:black}.muted,.ranks,.files{color:#444}article{background:#eee;break-inside:avoid}a{color:inherit}}
''');
    for (final entry in pieceImages.entries) {
      if (!RegExp(r'^[prnbqkPRNBQK]$').hasMatch(entry.key) ||
          !RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(entry.value)) {
        throw const FormatException('Invalid embedded piece');
      }
      out.write(
        '.p${entry.key.codeUnitAt(0)}{background-image:url(data:image/webp;base64,${entry.value})}',
      );
    }
    out.write(
      '</style><header id="game-list"><h1>${t('title')}</h1><p>${t('explanation')}</p><p class="muted retention">${t('retention')}</p><p class="note">${t('partial')}</p></header>',
    );
    if (report.incomplete) out.write('<p class="note">${t('missing')}</p>');
    out.write(
      '<style>nav{margin:24px 0 32px;border-top:1px solid #3c483b;border-bottom:1px solid #3c483b;padding:14px 0}.jump-row{display:grid;grid-template-columns:90px minmax(0,1fr) auto;gap:12px;align-items:baseline;padding:8px 0;font-size:14px}.game-heading{display:flex;flex-wrap:wrap;gap:6px 16px;align-items:baseline;justify-content:space-between}.game-heading h2{margin:0}.game-heading time{font-size:14px;color:#bbc9b8}.game-section{scroll-margin-top:16px;margin-top:36px}.players,.game-meta{display:flex;flex-wrap:wrap;gap:4px 20px;margin:8px 0}.opening,.retention,.back{font-size:14px}.jump-title{font-size:14px;color:#bbc9b8}.jump-row>*{overflow-wrap:anywhere;min-width:0}@media(max-width:680px){.jump-row{grid-template-columns:80px minmax(0,1fr);gap:0 10px}.index-result{grid-column:2}article{grid-template-columns:minmax(0,1fr)}}',
    );
    for (final outcome in RecentGameOutcome.values) {
      final color = outcome.colorFor(Brightness.dark);
      if (color != null) {
        out.write(
          '.result-${outcome.name}{color:#${color.toARGB32().toRadixString(16).substring(2)}}',
        );
      }
    }
    out.write('</style>');
    final games = report.games;
    String resultMarkup(SamplingReportGame g) =>
        '<span class="result-${g.outcome.name}">${e(g.result)}</span>';
    if (games.isNotEmpty) {
      out.write(
        '<nav aria-label="${t('jump')}"><p class="jump-title">${t('jump')}</p>',
      );
      var i = 0;
      for (final entry in games.entries) {
        final g = SamplingReportGame(report.summaries[entry.key] ?? {}, text);
        i++;
        out.write(
          '<div class="jump-row"><a href="#game-$i">${e(text['game']!.replaceAll('{number}', '$i'))}</a><span>${e(g.date)} · ${e(g.opening)}</span><span class="index-result">${resultMarkup(g)}</span></div>',
        );
      }
      out.write('</nav>');
    }
    var gameIndex = 0;
    var recordIndex = 0;
    for (final entry in games.entries) {
      final game = entry.value;
      final g = SamplingReportGame(report.summaries[entry.key] ?? {}, text);
      gameIndex++;
      out.write(
        '<section class="game-section" id="game-$gameIndex"><div class="game-heading"><h2>${e(text['game']!.replaceAll('{number}', '$gameIndex'))}</h2><time>${e(g.date)}</time></div><div class="players"><span><span class="muted">${t('white')}:</span> ${e(g.white)}</span><span><span class="muted">${t('black')}:</span> ${e(g.black)}</span></div><div class="game-meta">${resultMarkup(g)}<span>${e(g.timeControl)}</span><span class="muted">${e(text['records']!.replaceAll('{count}', '${game.length}'))}</span></div><p class="muted opening">${e(g.opening)}</p>',
      );
      for (final d in game) {
        final move = d.played, top = d.mostProbable;
        final matched = move != null && move.uci == top?.uci;
        out.write(
          '<article><div class="copy"><h3>${e(d.moveNumber)} ${move == null ? t('notPlayed') : '${t('played')}: ${e(move.san)}'}</h3><p class="settings muted">${e(samplingSettings(d, text, locale))}</p><div class="legend">',
        );
        String description(SamplingReportMove m) =>
            '${e(m.san)} · ${e(samplingPercent(m.probability, locale))}';
        if (matched) {
          out.write(
            '<p>${t('matched')}</p><p><i class="key played-key" aria-hidden="true"></i>${description(move)}</p>',
          );
        } else {
          if (move != null) {
            out.write(
              '<p><i class="key played-key" aria-hidden="true"></i>${t('played')} ${description(move)}</p>',
            );
          }
          if (top != null) {
            out.write(
              '<p><i class="key probable-key" aria-hidden="true"></i>${t('mostProbable')} ${description(top)}</p>',
            );
          }
        }
        out.write('</div>');
        if (move != null) {
          out.write(
            '<p class="chance">${e(samplingChance(move.san, move.probability, text, locale))}</p>',
          );
        }
        if (d.alternatives.isNotEmpty) {
          out.write('<div class="alternatives">${t('alternatives')}:<br>');
          for (final m in d.alternatives) {
            out.write('<span class="option">${description(m)}</span>');
          }
          out.write('</div>');
        }
        out.write(
          '<small>${e('${d.startedAt.toIso8601String().substring(0, 16).replaceFirst('T', ' ')} UTC')}</small></div>${samplingReportBoard(d)}</article>',
        );
        if (++recordIndex % 32 == 0) await out.flush();
      }
      out.write(
        '<a class="back" href="#game-list">${t('back')} ↑</a></section>',
      );
    }
    out.write(
      '<footer>Mobile Maia · Chess pieces: Colin M. L. Burnett, via Lichess / chessground (WebP conversion). <a href="https://creativecommons.org/licenses/by-sa/3.0/">CC BY-SA 3.0</a> · <a href="https://commons.wikimedia.org/wiki/Category:SVG_chess_pieces">Original artwork</a>.</footer></html>',
    );
    await out.flush();
  } finally {
    await out.close();
  }
}
