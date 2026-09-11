import 'dart:convert';

import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  final session = AnalysisSession.fromPgn(
    '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 *',
  );
  final moves = session.sanMoves.skip(1).toList();
  RecordedVariation segment(
    int start,
    int end, {
    List<RecordedVariation> children = const [],
    String? comment,
  }) => RecordedVariation(
    basePly: start + 1,
    baseFen: session.positions[start + 1],
    sanMoves: moves.sublist(start, end),
    children: children,
    annotations: comment == null
        ? const []
        : [
            {
              'comments': [comment],
              'nags': [1],
            },
          ],
  );

  test(
    'all 32 segmentations of one continuation merge with notes at their moves',
    () {
      final representations = <RecordedVariation>[];
      for (var mask = 0; mask < 32; mask++) {
        final cuts = [
          0,
          for (var i = 1; i < moves.length; i++)
            if ((mask & (1 << (i - 1))) != 0) i,
          moves.length,
        ];
        RecordedVariation? tail;
        for (var i = cuts.length - 2; i >= 0; i--) {
          tail = segment(
            cuts[i],
            cuts[i + 1],
            children: tail == null ? [] : [tail],
            comment: 'Note at ${cuts[i]}',
          );
        }
        representations.add(tail!);
      }
      final result = VariationTree.normalize(representations);
      expect(result, hasLength(1));
      expect(result.single.sanMoves, moves);
      expect(result.single.children, isEmpty);
      for (var i = 0; i < moves.length; i++) {
        expect(result.single.annotations[i]['comments'], ['Note at $i']);
        expect(result.single.annotations[i]['nags'], [1]);
      }
      final once = jsonEncode(result.map((v) => v.toJson()).toList());
      expect(
        jsonEncode(
          VariationTree.normalize([...result, ...representations])
              .map((v) => v.toJson())
              .toList(),
        ),
        once,
      );
    },
  );

  test('duplicate parents retain different child continuations and all annotations', () {
    final end = session.positions[3];
    final alternate = RecordedVariation(
      basePly: 3,
      baseFen: end,
      sanMoves: ['Nc6'],
      annotations: const [
        {
          'startingComments': ['Other idea'],
        },
      ],
    );
    final a = segment(0, 2, comment: 'First note', children: [segment(2, 6)]);
    final b = segment(0, 6, comment: 'Second note', children: [alternate]);
    final normalized = VariationTree.normalize([a, b]);
    expect(normalized, hasLength(1));
    expect(normalized.single.annotations.first['comments'], [
      'First note',
      'Second note',
    ]);
    expect(normalized.single.children.single.sanMoves, ['Nc6']);
    expect(
      normalized.single.children.single.annotations.first['startingComments'],
      ['Other idea'],
    );
    final main = AnalysisSession.fromPgn('1. e4 e5 *');
    final pgn = PgnVariationExporter.export(
      main.pgn,
      main.sanMoves,
      normalized,
      mainPositions: main.positions,
    );
    final parsed = dc.PgnGame.parsePgn(pgn);
    final branch = parsed.moves.children.first.children[1];
    expect(branch.data.san, 'c5');
    expect(branch.children.first.children.map((n) => n.data.san), [
      'd6',
      'Nc6',
    ]);
    expect(AnalysisSession.fromPgn(pgn).uciMoves, main.uciMoves);
  });

  for (final length in [0, 1, 3]) {
    test(
      'protected mainline of $length plies never absorbs an undone continuation',
      () {
        final main = AnalysisSession.fromPgn('1. e4 c5 2. Nf3 *');
        final child = RecordedVariation(
          basePly: length,
          baseFen: main.positions[length],
          sanMoves: length == 3 ? ['d6'] : main.sanMoves.skip(length).toList(),
        );
        final root = RecordedVariation(
          basePly: 0,
          baseFen: main.positions.first,
          sanMoves: main.sanMoves.take(length).toList(),
          children: [child],
        );
        final normalized = VariationTree.normalize([
          root,
          root,
        ], preserveFirst: true);
        expect(normalized, hasLength(1));
        expect(normalized.single.sanMoves, main.sanMoves.take(length).toList());
        expect(normalized.single.children, hasLength(1));
        final seed = length == 0
            ? AnalysisSession.start()
            : AnalysisSession.fromPgn(
                '${main.sanMoves.take(length).join(' ')} *',
              );
        final exported = PgnVariationExporter.export(
          seed.pgn,
          seed.sanMoves,
          normalized.single.children,
          mainPositions: seed.positions,
          preserveEmptyMainline: true,
        );
        expect(AnalysisSession.fromPgn(exported).uciMoves, seed.uciMoves);
        expect(exported, contains('Unplayed takeback line'));
      },
    );
  }

  test('the same SAN at a different parent ply or different capture rights stays separate', () {
    final ep = AnalysisSession.fromPgn('1. e4 a6 2. e5 d5 *').positions.last;
    final noEp = ep.replaceFirst(' d6 ', ' - ');
    final result = VariationTree.normalize([
      RecordedVariation(basePly: 4, baseFen: ep, sanMoves: const ['Nf3']),
      RecordedVariation(basePly: 4, baseFen: noEp, sanMoves: const ['Nf3']),
      RecordedVariation(basePly: 6, baseFen: ep, sanMoves: const ['Nf3']),
    ]);
    expect(result, hasLength(3));
  });

  test(
    'legacy equivalent en-passant spellings combine without mutating inputs',
    () {
      final old = session.positions[1];
      final canonical = dc.Chess.fromSetup(dc.Setup.parseFen(old)).fen;
      final input = [
        RecordedVariation(
          basePly: 1,
          baseFen: old,
          sanMoves: const ['c5'],
          annotations: const [
            {
              'comments': ['First'],
            },
          ],
        ),
        RecordedVariation(
          basePly: 1,
          baseFen: canonical,
          sanMoves: const ['c5'],
          annotations: const [
            {
              'comments': ['Second'],
            },
          ],
        ),
      ];
      final before = jsonEncode(input.map((v) => v.toJson()).toList());
      final result = VariationTree.normalize(input);
      expect(result, hasLength(1));
      expect(result.single.annotations.first['comments'], ['First', 'Second']);
      expect(jsonEncode(input.map((v) => v.toJson()).toList()), before);
    },
  );
}
