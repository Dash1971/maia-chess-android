import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('variation round trips agree with independent python-chess trees', () {
    final corpus = jsonDecode(
      File(
        Platform.environment['MAIA_VARIATION_CORPUS'] ??
            'test/fixtures/variation_oracle.json',
      ).readAsStringSync(),
    ) as Map;
    final random = Random(corpus['seed'] as int);

    RecordedVariation split(RecordedVariation line) {
      final children = line.children.map(split).toList();
      if (line.sanMoves.length < 2) {
        return RecordedVariation(
          basePly: line.basePly,
          baseFen: line.baseFen,
          sanMoves: line.sanMoves,
          annotations: line.annotations,
          children: children,
        );
      }
      final cut = 1 + random.nextInt(line.sanMoves.length - 1);
      final position = chess.Chess.fromFEN(line.baseFen);
      for (final san in line.sanMoves.take(cut)) {
        expect(position.move(san), isTrue);
      }
      final boundary = line.basePly + cut;
      return RecordedVariation(
        basePly: line.basePly,
        baseFen: line.baseFen,
        sanMoves: line.sanMoves.take(cut).toList(),
        annotations: line.annotations.take(cut).toList(),
        children: [
          split(
            RecordedVariation(
              basePly: boundary,
              baseFen: position.fen,
              sanMoves: line.sanMoves.skip(cut).toList(),
              annotations: line.annotations.skip(cut).toList(),
              children: children.where((v) => v.basePly >= boundary).toList(),
            ),
          ),
          ...children.where((v) => v.basePly < boundary),
        ],
      );
    }

    void verify(String pgn, Map row) {
      final game = dc.PgnGame.parsePgn(pgn);
      final nodes = <String, Map<String, Object>>{};
      final leaves = <String>[];
      void walk(
        dc.PgnNode<dc.PgnNodeData> node,
        dc.Position position,
        List<String> prefix,
      ) {
        for (final child in node.children) {
          final move = position.parseSan(child.data.san);
          expect(move, isNotNull, reason: child.data.san);
          // dartchess represents castling as king-to-rook; python-chess uses
          // the king's destination in standard UCI. Compare the same notation.
          final uci = child.data.san.startsWith('O-O') && move is dc.NormalMove
              ? '${move.from.name}${child.data.san.startsWith('O-O-O') ? 'c' : 'g'}${move.from.name[1]}'
              : move!.uci;
          final path = [...prefix, uci];
          final key = path.join(' ');
          final notes = {
            'comments': (child.data.comments ?? []).toSet().toList()..sort(),
            'nags': (child.data.nags ?? []).toSet().toList()..sort(),
          };
          if (nodes.containsKey(key)) expect(nodes[key], notes);
          nodes[key] = notes;
          if (child.children.isEmpty) leaves.add(key);
          walk(child, position.play(move!), path);
        }
      }

      walk(
        game.moves,
        dc.Chess.fromSetup(
          dc.Setup.parseFen(
            game.headers['FEN'] ?? chess.Chess.DEFAULT_POSITION,
          ),
        ),
        [],
      );
      expect(nodes, row['nodes']);
      expect(
        leaves..sort(),
        row['leaves'],
        reason: 'Every branch must occur once',
      );
      final session = AnalysisSession.fromPgn(pgn);
      expect(session.uciMoves, row['mainline']);
      expect(
        dc.Chess.fromSetup(dc.Setup.parseFen(session.positions.last)).fen,
        row['endFen'],
      );
    }

    final watch = Stopwatch()..start();
    for (final row in (corpus['cases'] as List).cast<Map>()) {
      final session = AnalysisSession.fromPgn(row['pgn'] as String);
      final roots = PgnVariationExporter.parseTree(session.pgn);
      final main = roots.first;
      final original = PgnVariationExporter.annotationsForMainline(
        session.sanMoves,
        roots,
      );
      final mixed = [...original, ...original.map(split)];
      var pgn = PgnVariationExporter.export(
        session.pgn,
        session.sanMoves,
        mixed,
        mainPositions: session.positions,
        mainAnnotations: main.annotations,
      );
      verify(pgn, row);
      for (var visit = 0; visit < 3; visit++) {
        final current = PgnVariationExporter.parseTree(pgn);
        final next = PgnVariationExporter.export(
          pgn,
          session.sanMoves,
          [
            ...PgnVariationExporter.annotationsForMainline(
              session.sanMoves,
              current,
            ),
            ...mixed,
          ],
          mainPositions: session.positions,
          mainAnnotations: current.first.annotations,
        );
        expect(
          next,
          pgn,
          reason: 'Merging the same saved tree must be idempotent',
        );
        verify(next, row);
        pgn = next;
      }
    }
    // A repeatable host benchmark, not a claim about physical-phone speed.
    // ignore: avoid_print
    print(
      'VARIATION ORACLE: ${(corpus['cases'] as List).length} trees, '
      '4 round trips each, ${watch.elapsedMilliseconds} ms',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
