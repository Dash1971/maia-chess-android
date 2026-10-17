import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

class Draw implements Random {
  Draw(this.value);
  final double value;
  int calls = 0;
  @override
  double nextDouble() {
    calls++;
    return value;
  }

  @override
  int nextInt(int max) => throw StateError('unexpected RNG');
  @override
  bool nextBool() => throw StateError('unexpected RNG');
}

List<double> floats(Map data) {
  final raw = base64Decode(data['data'] as String);
  expectSync(
    sha256.convert(raw).toString(),
    data['sha256'],
    reason: 'tensor checksum',
  );
  final bytes = ByteData.sublistView(raw);
  return List.generate(
    data['length'] as int,
    (i) => bytes.getFloat32(i * 4, Endian.little),
  );
}

// Independent encoder: parse the exported FEN window directly, with no call
// to MaiaEncoding. The extra ponder plane is zero.
List<double> encode(List<dynamic> fens) {
  final out = List<double>.filled(6208, 0);
  for (var t = 0; t < 8; t++) {
    final parts = (fens[t] as String).split(' ');
    final black = parts[1] == 'b';
    var square = 56;
    for (final symbol in parts.first.split('')) {
      if (symbol == '/') {
        square -= 16;
        continue;
      }
      final n = int.tryParse(symbol);
      if (n != null) {
        square += n;
        continue;
      }
      final oriented = black ? square ^ 56 : square;
      final own = (symbol == symbol.toUpperCase()) != black;
      final piece = 'pnbrqk'.indexOf(symbol.toLowerCase()) + (own ? 0 : 6);
      out[oriented * 97 + t * 12 + piece] = 1;
      square++;
    }
  }
  return out;
}

void replay(Map record) {
  expectSync(
    floats(record['tokens']),
    encode(record['historyWindow']),
    reason: 'input encoding',
  );
  final logits = floats(record['logits']);
  final trace = record['sampling'] as Map;
  final legal = trace['legalOrder'] as List;
  final board = chess.Chess.fromFEN(record['fen']);
  final moves = board.moves({'asObjects': true}).cast<chess.Move>();
  expectSync(
    legal.map((m) => m['uci']),
    moves.map(MaiaEncoding.uci),
    reason: 'legal order',
  );
  // Independent vocabulary index: square pair, followed by promotions in
  // file/from, file/to, q/r/b/n order (mirrored vertically for Black).
  int index(String uci) {
    int sq(String s) => s.codeUnitAt(0) - 97 + (int.parse(s[1]) - 1) * 8;
    var from = sq(uci.substring(0, 2));
    var to = sq(uci.substring(2, 4));
    if (record['side'] == 'b') {
      from ^= 56;
      to ^= 56;
    }
    return uci.length == 5
        ? 4096 + (from % 8) * 32 + (to % 8) * 4 + 'qrbn'.indexOf(uci[4])
        : from * 64 + to;
  }

  for (final m in legal) {
    expectSync(m['index'], index(m['uci']), reason: 'model index');
  }
  final scores = legal.map((m) => logits[m['index'] as int]).toList();
  final peak = scores.reduce(max);
  final raw = scores.map((v) => exp(v - peak)).toList();
  final sum = raw.reduce((a, b) => a + b);
  final policy = record['rawLegalPolicy'] as List;
  for (var i = 0; i < raw.length; i++) {
    expectSync(
      policy[i]['probability'],
      closeTo(raw[i] / sum, 1e-14),
      reason: 'raw probability',
    );
  }
  if (trace['mode'] == 'argmax') {
    expectSync(trace['random'], isNull);
    expectSync(trace['selected'], legal[scores.indexOf(peak)]['uci']);
  } else {
    final temp = (trace['effectiveTemperature'] as num).toDouble();
    final random = trace['random'] as Map;
    final ordered = random['weightedOrder'] as List;
    final ids = {for (var i = 0; i < legal.length; i++) legal[i]['uci']: i};
    double last = double.infinity;
    for (final item in ordered) {
      final weight = exp(scores[ids[item['uci']]!] / temp - peak / temp);
      expectSync(
        item['weight'],
        closeTo(weight, 1e-12),
        reason: 'temperature weight',
      );
      expectSync(weight <= last, isTrue, reason: 'TopP order');
      last = weight;
    }
    expectSync(ordered.map((v) => v['uci']).toSet(), ids.keys.toSet());
    final total = ordered.fold<double>(0, (v, m) => v + (m['weight'] as num));
    var mass = 0.0;
    var count = 0;
    for (final m in ordered) {
      mass += (m['weight'] as num) / total;
      count++;
      if (trace['effectiveTopP'] < 1 && mass >= trace['effectiveTopP']) break;
    }
    expectSync(random['nucleusCount'], count, reason: 'TopP crossing');
    final nucleus = ordered.take(count).toList();
    final retained = nucleus.fold<double>(
      0,
      (v, m) => v + (m['weight'] as num),
    );
    var target = (random['draw'] as num) * retained;
    expectSync(random['total'], retained);
    expectSync(random['target'], target);
    String? chosen;
    for (final item in nucleus) {
      target -= item['weight'] as num;
      if (target <= 0) {
        chosen = item['uci'];
        break;
      }
    }
    expectSync(
      trace['selected'],
      chosen ?? nucleus.last['uci'],
      reason: 'recorded random draw',
    );
  }
  if (record['outcome'] == 'committed') {
    expectSync(record['committedMove'], trace['selected']);
    final selected = moves.singleWhere(
      (m) => MaiaEncoding.uci(m) == trace['selected'],
    );
    expectSync(board.move(selected), isTrue);
    expectSync(record['committedFen'], board.fen, reason: 'committed board');
  }
}

Future<List<Map>> readExport(SamplingCapture store) async {
  final file = await store.export();
  final lines = await file.readAsLines();
  final footer = jsonDecode(lines.last) as Map;
  expectSync(
    footer['contentSha256'],
    sha256
        .convert(utf8.encode('${lines.take(lines.length - 1).join('\n')}\n'))
        .toString(),
  );
  final records = <Map>[];
  for (final line in lines.skip(1).take(lines.length - 2)) {
    final envelope = jsonDecode(line) as Map;
    expectSync(
      envelope['sha256'],
      sha256.convert(utf8.encode(envelope['record'])).toString(),
    );
    records.add(jsonDecode(envelope['record']) as Map);
  }
  expectSync(footer['records'], records.length);
  return records;
}
