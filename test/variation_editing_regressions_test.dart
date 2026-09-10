import 'dart:convert';

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pgn = '''
[Result "*"]

1. e4 {Root note} e5 {Played reply}
(1... c5 {Sicilian} 2. Nf3 {Parent move}
  (2. Nc3 \$1 {Nested move} Nc6 {Nested reply}
    (2... a6 \$6 {Separate alternative}) 3. f4 {Leaf note})
  d6 {Parent tail}) 2. Nf3 Nc6 *
''';

// Compare actual move paths and their notes, independent of line segmentation
// and sibling order. Promotion may reorder a tree but must not lose its nodes.
Map<String, Object> _nodes(String pgn) {
  final result = <String, Object>{};
  void walk(dc.PgnNode<dc.PgnNodeData> node, List<String> prefix) {
    for (final child in node.children) {
      final path = [...prefix, child.data.san];
      final key = path.join(' ');
      expect(result.containsKey(key), isFalse, reason: 'Duplicate path: $key');
      result[key] = {
        'comments': child.data.comments ?? const [],
        'startingComments': child.data.startingComments ?? const [],
        'nags': child.data.nags ?? const [],
      };
      walk(child, path);
    }
  }

  walk(dc.PgnGame.parsePgn(pgn).moves, []);
  return result;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final action in ['Make main line', 'Promote variation']) {
    testWidgets(
      '$action on nested line preserves notes through editing and reopen',
      (tester) async {
        final original = AnalysisSession.fromPgn(_pgn);
        var session = original;
        var tree = PgnVariationExporter.parseTree(_pgn);
        var currentFen = original.positions.first;
        var revision = 0;

        Future<void> open() async {
          await tester.pumpWidget(
            MaterialApp(
              home: ReviewPage(
                key: ValueKey(revision++),
                positions: session.positions,
                uciMoves: session.uciMoves,
                sanMoves: session.sanMoves,
                pgn: session.pgn,
                playerIsWhite: true,
                initialVariations: tree,
                initialTreeIsAuthoritative: true,
                initialCurrentFen: currentFen,
                onHome: () {},
                evaluator: (_) async => const StockfishReview(0, ''),
                maiaEvaluator: (_, _) async => null,
                onSessionChanged: (fen, flipped, variations) async {
                  currentFen = fen;
                  tree = variations;
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Finder move(String san) => find.descendant(
          of: find.byKey(const ValueKey('analysis-move-list')),
          matching: find.text(san),
        );

        Future<void> edit(String san, String choice) async {
          await tester.ensureVisible(move(san));
          await tester.longPress(move(san));
          await tester.pumpAndSettle();
          await tester.tap(find.text(choice));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        String export() =>
            PgnVariationExporter.export(session.pgn, const [], tree);

        await open();
        await edit('Nc3', action);
        expect(_nodes(export()), _nodes(_pgn));
        expect(
          AnalysisSession.fromPgn(export()).sanMoves,
          action == 'Make main line'
              ? ['e4', 'c5', 'Nc3', 'Nc6', 'f4']
              : original.sanMoves,
        );
        if (action == 'Promote variation') {
          await edit('Nc3', action);
          expect(AnalysisSession.fromPgn(export()).sanMoves, [
            'e4',
            'c5',
            'Nc3',
            'Nc6',
            'f4',
          ]);
          expect(_nodes(export()), _nodes(_pgn));
        }

        await edit('a6', 'Delete from here');
        final expected = _nodes(_pgn)..remove('e4 c5 Nc3 a6');
        expect(_nodes(export()), expected);
        final selected = dc.Chess.fromSetup(dc.Setup.parseFen(currentFen)).fen;
        expect(
          tester
              .widget<cg.Chessboard>(find.byType(cg.Chessboard))
              .controller
              .fen,
          selected,
        );
        final finalPgn = export();
        for (var reopen = 0; reopen < 4; reopen++) {
          tree =
              (jsonDecode(jsonEncode(tree.map((v) => v.toJson()).toList()))
                      as List)
                  .map(
                    (v) => RecordedVariation.fromJson(
                      Map<String, dynamic>.from(v as Map),
                    ),
                  )
                  .toList();
          session = AnalysisSession.fromPgn(finalPgn);
          await open();
          expect(export(), finalPgn);
          expect(_nodes(export()), expected);
          expect(
            tester
                .widget<cg.Chessboard>(find.byType(cg.Chessboard))
                .controller
                .fen,
            selected,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
