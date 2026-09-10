import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('top-p includes the move that crosses its probability threshold', () {
    final game = chess.Chess();
    final legal = game.moves({'asObjects': true}).cast<chess.Move>();
    final logits = List<double>.filled(4352, -100);
    for (final entry in {'e2e4': 0.6, 'd2d4': 0.3, 'g1f3': 0.1}.entries) {
      logits[MaiaEncoding.moveIndex(entry.key, false)] = log(entry.value);
    }
    final sampled = <String>{};
    final random = Random(20260909);
    for (var i = 0; i < 200; i++) {
      sampled.add(
        MaiaEncoding.uci(
          MaiaEncoding.sampleLegalMove(
            game,
            legal,
            logits,
            topP: .8,
            random: random,
          ),
        ),
      );
    }
    expect(sampled, {'e2e4', 'd2d4'});
  });

  test(
    'a semantically corrupt primary checkpoint falls back to its backup',
    () async {
      final directory = await Directory.systemTemp.createTemp('maia-corrupt-');
      addTearDown(() => directory.delete(recursive: true));
      final store = SessionRepository(directory);
      await store.save({'type': 'game', 'pgn': '1. e4 *'});
      await store.save({'type': 'game', 'pgn': '1. d4 *'});
      final file = File('${directory.path}/active.json');
      final envelope = jsonDecode(await file.readAsString()) as Map;
      envelope['updatedAt'] = 42;
      await file.writeAsString(jsonEncode(envelope));
      final recent = await store.recent();
      expect(recent.single.data['pgn'], '1. e4 *');
    },
  );

  test('pasted PGN size limits count UTF-8 bytes', () {
    final source = '{${'♞' * 800000}} 1. e4 *';
    expect(() => AnalysisSession.fromPgn(source), throwsFormatException);
  });

  test(
    'position parser rejects excessive nesting before building a PGN tree',
    () {
      final nested =
          '1. e4 ${List.filled(2000, '(1. d4 ').join()}${')' * 2000} *';
      expect(() => AnalysisSession.fromPgn(nested), throwsFormatException);
    },
  );
}
