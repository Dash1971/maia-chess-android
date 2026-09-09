import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'opening lookup accepts both equivalent en-passant FEN formats',
    () async {
      await OpeningNames.load();
      for (final (move, eco) in [('e4', 'B00'), ('d4', 'A40')]) {
        final game = chess.Chess()..move(move);
        final canonical = dc.Chess.fromSetup(dc.Setup.parseFen(game.fen)).fen;
        expect(game.fen, isNot(canonical));
        final expected = OpeningNames.identifyPositions([canonical]);
        expect(expected, startsWith(eco));
        expect(OpeningNames.identifyPositions([game.fen]), expected);
        expect(
          OpeningNames.identify([move == 'e4' ? 'e2e4' : 'd2d4']),
          expected,
        );
      }
    },
  );

  Future<void> move(WidgetTester tester, String uci) async {
    tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
      dc.NormalMove.fromUci(uci),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a played pawn variation restores its selected position and orientation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: AnalysisSession.start(),
            maiaElo: 1600,
            evaluator: (_) async => const StockfishReview(0, 'e2e4'),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await move(tester, 'e2e4');
      await move(tester, 'e7e5');
      await tester.tap(find.byKey(const ValueKey('previous-move-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('previous-move-button')));
      await tester.pumpAndSettle();
      await move(tester, 'd2d4');
      await tester.tap(find.byTooltip('Flip board'));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      // Legacy saved positions can omit a non-capturable en-passant square.
      saved['currentFen'] = dc.Chess.fromSetup(
        dc.Setup.parseFen(saved['currentFen'] as String),
      ).fen;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: AnalysisSession.fromJson(
              Map<String, dynamic>.from(saved['session'] as Map),
            ),
            initialVariations: (saved['variations'] as List)
                .map(
                  (v) => RecordedVariation.fromJson(
                    Map<String, dynamic>.from(v as Map),
                  ),
                )
                .toList(),
            initialTreeIsAuthoritative: true,
            initialCurrentFen: saved['currentFen'] as String,
            initialFlipped: saved['flipped'] as bool,
            maiaElo: 1600,
            evaluator: (_) async => const StockfishReview(0, 'd7d5'),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      expect(board.controller.lastMove?.uci, 'd2d4');
      expect(board.orientation, dc.Side.black);
      expect(find.text('e4'), findsOneWidget);
      expect(find.text('e5'), findsOneWidget);
      expect(find.text('d4'), findsOneWidget);
    },
  );

  for (final legacy in [false, true]) {
    testWidgets(
      'playing an existing reply retains its continuation and comments (legacy=$legacy)',
      (tester) async {
        final session = AnalysisSession.fromPgn(
          '1. e4 e5 (1... c5 {Keep this note} 2. Nf3) *',
        );
        final json = PgnVariationExporter.parseTree(session.pgn).single
            .toJson();
        final child = (json['children'] as List).single as Map;
        child['baseFen'] = dc.Chess.fromSetup(
          dc.Setup.parseFen(child['baseFen'] as String),
        ).fen;
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisBoardPage(
              initialSession: session,
              initialCurrentFen: session.positions[1],
              initialVariations: legacy
                  ? [RecordedVariation.fromJson(json)]
                  : const [],
              initialTreeIsAuthoritative: legacy,
              maiaElo: 1600,
              evaluator: (_) async => const StockfishReview(0, 'c7c5'),
              maiaEvaluator: (_, _) async => null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await move(tester, 'c7c5');
        final saved = (await ActiveSessionStore.load())!;
        final lines = (saved['variations'] as List)
            .map(
              (v) => RecordedVariation.fromJson(
                Map<String, dynamic>.from(v as Map),
              ),
            )
            .toList();
        final exported = PgnVariationExporter.export(
          session.pgn,
          const [],
          lines,
        );
        expect(exported, contains('Nf3'));
        expect(exported, contains('Keep this note'));
        final root = lines.single;
        expect(root.children.single.sanMoves, ['c5', 'Nf3']);
        expect(
          chess.Chess.fromFEN(saved['currentFen'] as String).turn,
          chess.Color.WHITE,
        );
      },
    );
  }
}
