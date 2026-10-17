import 'dart:async';

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  testWidgets(
    'both engines receive only selected history and reject old mode results',
    (tester) async {
      final game = chess.Chess();
      final prefix = [game.fen];
      game.move('e4');
      final fen = game.fen;
      final requests =
          <
            ({int elo, List<String> positions, Completer<List<double>?> reply})
          >[];
      Future<List<double>?> evaluate(List<String> positions, int elo) {
        final reply = Completer<List<double>?>();
        requests.add((elo: elo, positions: List.of(positions), reply: reply));
        return reply.future;
      }

      Widget page(bool mode) => MaterialApp(
        home: ReviewPage(
          positions: [fen],
          historyPrefix: prefix,
          useMoveHistory: mode,
          uciMoves: const [],
          sanMoves: const [],
          playerIsWhite: true,
          pgn: '*',
          maiaElo: 600,
          secondMaiaElo: 700,
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e7e5'),
          maiaPolicyEvaluator: evaluate,
        ),
      );
      await tester.pumpWidget(page(false));
      await tester.pumpAndSettle();
      expect(requests.map((r) => r.elo), [600, 700]);
      expect(
        requests.every(
          (r) => r.positions.length == 2 && r.positions.last == fen,
        ),
        isTrue,
      );
      await tester.pumpWidget(page(true));
      await tester.pumpAndSettle();
      expect(requests, hasLength(4));
      List<double> policy(String move) {
        final result = List<double>.filled(4352, -10);
        result[MaiaEncoding.moveIndex(move, true)] = 10;
        return result;
      }

      for (final r in requests.skip(2)) {
        r.reply.complete(policy('e7e5'));
      }
      await tester.pumpAndSettle();
      for (final r in requests.take(2)) {
        r.reply.complete(policy('d7d5'));
      }
      await tester.pumpAndSettle();
      final rows = [
        find.byKey(const ValueKey('maia-engine-line')),
        find.byKey(const ValueKey('second-maia-engine-line')),
      ];
      for (final row in rows) {
        final text = tester
            .widgetList<RichText>(
              find.descendant(of: row, matching: find.byType(RichText)),
            )
            .map((widget) => widget.text.toPlainText())
            .join(' ');
        expect(text, contains('e5'));
        expect(text, isNot(contains('d5')));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'transposed variations use separate history and continuation follows selected branch',
    (tester) async {
      final histories = <List<String>>[];
      final transposedReplies = <Completer<String?>>[];
      List<String>? continued;
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: const [chess.Chess.DEFAULT_POSITION],
            uciMoves: const [],
            sanMoves: const [],
            playerIsWhite: true,
            pgn: '*',
            useMoveHistory: true,
            onHome: () {},
            onPlayFromHistory: (fen, positions) async {
              continued = positions;
            },
            evaluator: (_) async => const StockfishReview(0, ''),
            maiaEvaluator: (positions, _) async {
              histories.add(List.of(positions));
              if (positions.length == 5) {
                final reply = Completer<String?>();
                transposedReplies.add(reply);
                return reply.future;
              }
              final game = chess.Chess.fromFEN(positions.last);
              final move = game
                  .moves({'asObjects': true})
                  .cast<chess.Move>()
                  .first;
              return MaiaEncoding.uci(move);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> move(String uci) async {
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
          dc.NormalMove.fromUci(uci),
        );
        await tester.pumpAndSettle();
      }

      for (final uci in ['g1f3', 'g8f6', 'f3g1', 'f6g8']) {
        await move(uci);
      }
      final first = List<String>.of(histories.last);
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(find.byTooltip('Previous move'));
        await tester.tap(find.byTooltip('Previous move'));
        await tester.pumpAndSettle();
      }
      for (final uci in ['b1c3', 'b8c6', 'c3b1', 'c6b8']) {
        await move(uci);
      }
      final second = histories.last;
      expect(first.last, second.last);
      expect(first, hasLength(5));
      expect(second, hasLength(5));
      expect(first[1], isNot(second[1]));
      expect(
        MaiaEncoding.historyKey(first, useMoveHistory: true),
        isNot(MaiaEncoding.historyKey(second, useMoveHistory: true)),
      );
      expect(transposedReplies, hasLength(2));
      transposedReplies.last.complete('e2e4');
      await tester.pumpAndSettle();
      transposedReplies.first.complete('d2d4');
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('maia-engine-line'));
      expect(
        find.descendant(of: row, matching: find.text('e4')),
        findsOneWidget,
      );
      expect(find.descendant(of: row, matching: find.text('d4')), findsNothing);
      // The completed first branch must never leak into the selected second one.
      expect(second, isNot(contains(first[1])));
      await tester.tap(find.byTooltip('Analysis menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue from here'));
      await tester.pumpAndSettle();
      expect(continued, second);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
