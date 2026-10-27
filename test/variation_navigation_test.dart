import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/variation_navigation_game.dart';

final _moves = find.byKey(const ValueKey('analysis-move-list'));
final _back = find.byKey(const ValueKey('previous-move-button'));
final _next = find.byKey(const ValueKey('next-move-button'));

String _canonical(String fen) => dc.Chess.fromSetup(dc.Setup.parseFen(fen)).fen;

String _fen(RecordedVariation line, int index) {
  final board = chess.Chess.fromFEN(line.baseFen);
  for (final san in line.sanMoves.take(index)) {
    expect(board.move(san), isTrue);
  }
  return board.fen;
}

Finder _move(String san) =>
    find.descendant(of: _moves, matching: find.text(san));

void _expectSelection(WidgetTester tester, Finder move, String fen) {
  final material = move.evaluate().single.widget is Material
      ? move
      : find.ancestor(of: move, matching: find.byType(Material)).first;
  expect(tester.widget<Material>(material).color, isNot(Colors.transparent));
  expect(
    find.descendant(
      of: _moves,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Material &&
            widget.key is ValueKey<String> &&
            widget.color != Colors.transparent,
      ),
    ),
    findsOneWidget,
  );
  final board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
  expect(board.controller.fen, _canonical(fen));
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  AnalysisSession session,
  String fen, {
  bool persistent = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: persistent
          ? AnalysisBoardPage(
              initialSession: session,
              initialCurrentFen: fen,
              maiaElo: 1600,
              evaluator: (_) async => const StockfishReview(0, ''),
              maiaEvaluator: (_, _) async => null,
            )
          : ReviewPage(
              positions: session.positions,
              sanMoves: session.sanMoves,
              uciMoves: session.uciMoves,
              pgn: session.pgn,
              playerIsWhite: true,
              initialVariations: PgnVariationExporter.parseTree(session.pgn)
                  .single
                  .children,
              initialCurrentFen: fen,
              onHome: () {},
              evaluator: (_) async => const StockfishReview(0, ''),
              maiaEvaluator: (_, _) async => null,
            ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final persistent in [true, false]) {
    testWidgets(
      'move 16 Back returns to highlighted main line (saved=$persistent)',
      (tester) async {
        final session = AnalysisSession.fromPgn(variationNavigationPgn);
        final root = PgnVariationExporter.parseTree(session.pgn).single;
        final line = root.children.singleWhere((v) => v.basePly == 30);
        await _open(tester, session, _fen(line, 2), persistent: persistent);
        _expectSelection(tester, _move('Qf6'), _fen(line, 2));
        await _tap(tester, _back);
        _expectSelection(tester, _move('Qc3'), _fen(line, 1));
        await _tap(tester, _back);
        _expectSelection(
          tester,
          find.byKey(const ValueKey('mainline-move-29')),
          session.positions[30],
        );
        expect(
          tester
              .widget<cg.Chessboard>(find.byType(cg.Chessboard))
              .controller
              .lastMove
              ?.uci,
          session.uciMoves[29],
        );
        expect(tester.widget<InkResponse>(_back).onTap, isNotNull);
        await _tap(tester, _back);
        _expectSelection(
          tester,
          find.byKey(const ValueKey('mainline-move-28')),
          session.positions[29],
        );
        await _tap(tester, _next);
        await _tap(tester, _next);
        _expectSelection(
          tester,
          find.byKey(const ValueKey('mainline-move-30')),
          session.positions[31],
        );

        if (persistent) {
          final saved = (await ActiveSessionStore.load())!;
          final tree = (saved['variations'] as List)
              .map(
                (v) => RecordedVariation.fromJson(
                  Map<String, dynamic>.from(v as Map),
                ),
              )
              .toList();
          expect(
            PgnVariationExporter.export(session.pgn, const [], tree),
            PgnVariationExporter.export(session.pgn, const [], [root]),
          );
        }
      },
    );
  }

  testWidgets('nested branch Back returns through its actual parent', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn(variationNavigationPgn);
    final root = PgnVariationExporter.parseTree(session.pgn).single;
    final parent = root.children.singleWhere((v) => v.basePly == 16);
    final nested = parent.children.single;
    await _open(tester, session, _fen(nested, 1));
    await _tap(tester, _back);
    _expectSelection(tester, _move('Bxf7+'), _fen(parent, 1));
    await _tap(tester, _next);
    _expectSelection(tester, _move('Kxf7'), _fen(parent, 2));
    await _tap(tester, _back);
    await _tap(tester, _back);
    _expectSelection(
      tester,
      find.byKey(const ValueKey('mainline-move-15')),
      session.positions[16],
    );
    await _tap(tester, _next);
    _expectSelection(
      tester,
      find.byKey(const ValueKey('mainline-move-16')),
      session.positions[17],
    );
  });

  testWidgets(
    'root alternative exits at the start and Forward follows main line',
    (tester) async {
      final session = AnalysisSession.fromPgn('1. e4 (1. d4 d5) e5 *');
      final lines = PgnVariationExporter.parseTree(session.pgn);
      await _open(tester, session, _fen(lines[1], 1));
      await _tap(tester, _back);
      expect(tester.widget<InkResponse>(_back).onTap, isNull);
      expect(
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).controller.fen,
        _canonical(session.positions.first),
      );
      await _tap(tester, _next);
      _expectSelection(
        tester,
        find.byKey(const ValueKey('mainline-move-0')),
        session.positions[1],
      );
    },
  );

  testWidgets('custom black-to-move starting FEN uses relative branch plies', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn('''
[SetUp "1"]
[FEN "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 42"]
[Result "*"]

42... e5 43. e4 (43. d4 d5) Nc6 *
''');
    final root = PgnVariationExporter.parseTree(session.pgn).single;
    final branch = root.children.single;
    await _open(tester, session, _fen(branch, 1));
    await _tap(tester, _back);
    _expectSelection(
      tester,
      find.byKey(const ValueKey('mainline-move-0')),
      session.positions[1],
    );
    await _tap(tester, _back);
    expect(tester.widget<InkResponse>(_back).onTap, isNull);
    await _tap(tester, _next);
    await _tap(tester, _next);
    _expectSelection(
      tester,
      find.byKey(const ValueKey('mainline-move-1')),
      session.positions[2],
    );
  });

  testWidgets('returned main-line selection survives save and reopen', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn(variationNavigationPgn);
    final root = PgnVariationExporter.parseTree(session.pgn).single;
    final branch = root.children.singleWhere((v) => v.basePly == 30);
    await _open(tester, session, _fen(branch, 1));
    await _tap(tester, _back);
    await _tap(tester, find.byTooltip('Flip board'));
    final saved = (await ActiveSessionStore.load())!;
    final tree = (saved['variations'] as List)
        .map(
          (v) =>
              RecordedVariation.fromJson(Map<String, dynamic>.from(v as Map)),
        )
        .toList();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisBoardPage(
          initialSession: AnalysisSession.fromJson(
            Map<String, dynamic>.from(saved['session'] as Map),
          ),
          initialVariations: tree,
          initialTreeIsAuthoritative: true,
          initialCurrentFen: saved['currentFen'] as String,
          initialFlipped: saved['flipped'] as bool,
          maiaElo: 1600,
          evaluator: (_) async => const StockfishReview(0, ''),
          maiaEvaluator: (_, _) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectSelection(
      tester,
      find.byKey(const ValueKey('mainline-move-29')),
      session.positions[30],
    );
    expect(
      tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).orientation,
      dc.Side.black,
    );
    await _tap(tester, _next);
    _expectSelection(
      tester,
      find.byKey(const ValueKey('mainline-move-30')),
      session.positions[31],
    );
    expect(tree.single.toJson(), root.toJson());
  });

  testWidgets(
    'all main-line moves remain navigable through underpromotion and mate',
    (tester) async {
      final session = AnalysisSession.fromPgn(variationNavigationPgn);
      await _open(tester, session, session.positions.first);
      expect(tester.widget<InkResponse>(_back).onTap, isNull);
      for (var ply = 1; ply < session.positions.length; ply++) {
        await _tap(tester, _next);
        _expectSelection(
          tester,
          find.byKey(ValueKey('mainline-move-${ply - 1}')),
          session.positions[ply],
        );
        expect(
          tester
              .widget<cg.Chessboard>(find.byType(cg.Chessboard))
              .controller
              .lastMove
              ?.uci,
          session.uciMoves[ply - 1],
        );
      }
      expect(session.sanMoves, contains('h8=R'));
      expect(session.sanMoves.last, 'Ra4#');
      expect(tester.widget<InkResponse>(_next).onTap, isNull);
      for (var ply = session.positions.length - 2; ply > 0; ply--) {
        await _tap(tester, _back);
        _expectSelection(
          tester,
          find.byKey(ValueKey('mainline-move-${ply - 1}')),
          session.positions[ply],
        );
      }
      await _tap(tester, _back);
      expect(tester.widget<InkResponse>(_back).onTap, isNull);
      expect(
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).controller.fen,
        _canonical(session.positions.first),
      );
    },
  );

  testWidgets(
    'repeated branch exits retain annotations and all continuations',
    (tester) async {
      final session = AnalysisSession.fromPgn(
        '1. e4 {Main note} e5 (1... c5 {Branch note} 2. Nf3) 2. Nc3 *',
      );
      final root = PgnVariationExporter.parseTree(session.pgn).single;
      final branch = root.children.single;
      await _open(tester, session, _fen(branch, 2));
      for (var attempt = 0; attempt < 40; attempt++) {
        await _tap(tester, _move('Nf3'));
        await _tap(tester, _back);
        await _tap(tester, _back);
        _expectSelection(
          tester,
          find.byKey(const ValueKey('mainline-move-0')),
          session.positions[1],
        );
        await _tap(tester, _next);
        _expectSelection(
          tester,
          find.byKey(const ValueKey('mainline-move-1')),
          session.positions[2],
        );
      }
      final saved = (await ActiveSessionStore.load())!;
      final tree = (saved['variations'] as List).single as Map;
      expect(
        RecordedVariation.fromJson(Map<String, dynamic>.from(tree)).toJson(),
        root.toJson(),
      );
    },
  );

  testWidgets(
    'late analysis from an exited branch cannot replace parent results',
    (tester) async {
      final session = AnalysisSession.fromPgn('1. e4 e5 (1... c5 2. Nf3) *');
      final root = PgnVariationExporter.parseTree(session.pgn).single;
      final branch = root.children.single;
      final delayed = Completer<StockfishReview>();
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: session,
            initialCurrentFen: _fen(branch, 1),
            maiaElo: 1600,
            evaluator: (fen) => fen == _fen(branch, 1)
                ? delayed.future
                : Future.value(const StockfishReview(125, '')),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(_back);
      await tester.pump();
      delayed.complete(const StockfishReview(999, ''));
      await tester.pumpAndSettle();
      _expectSelection(
        tester,
        find.byKey(const ValueKey('mainline-move-0')),
        session.positions[1],
      );
      expect(find.text('+10.0'), findsNothing);
      expect(find.text('+1.3'), findsWidgets);
    },
  );

  for (final persistent in [true, false]) {
    testWidgets(
      'rapid taps advance each ply without waiting for a frame (saved=$persistent)',
      (tester) async {
        final session = AnalysisSession.fromPgn(variationNavigationPgn);
        await _open(
          tester,
          session,
          session.positions.first,
          persistent: persistent,
        );
        for (var ply = 1; ply <= 24; ply++) {
          await tester.tap(_next);
          expect(
            tester
                .widget<cg.Chessboard>(find.byType(cg.Chessboard))
                .controller
                .fen,
            _canonical(session.positions[ply]),
            reason: 'Every tap must advance immediately, before rendering or engine results.',
          );
        }
        await tester.pumpAndSettle();
        _expectSelection(
          tester,
          find.byKey(const ValueKey('mainline-move-23')),
          session.positions[24],
        );
        for (var ply = 23; ply >= 0; ply--) {
          await tester.tap(_back);
          expect(
            tester
                .widget<cg.Chessboard>(find.byType(cg.Chessboard))
                .controller
                .fen,
            _canonical(session.positions[ply]),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.widget<InkResponse>(_back).onTap, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final persistent in [true, false]) {
    for (final nested in [true, false]) {
      for (final control in [_back, _next]) {
        testWidgets(
          'hold ${control == _back ? "Left" : "Right"} returns ${nested ? "nested" : "top-level"} branch to main line (saved=$persistent)',
          (tester) async {
            final session = AnalysisSession.fromPgn(
              '1. e4 e5 (1... c5 2. Nf3 (2. Nc3 Nc6) d6) 2. Bc4 Nf6 *',
            );
            final root = PgnVariationExporter.parseTree(session.pgn).single;
            final parent = root.children.single;
            final branch = nested ? parent.children.single : parent;
            await _open(
              tester,
              session,
              _fen(branch, branch.sanMoves.length),
              persistent: persistent,
            );
            expect(
              tester.widget<InkResponse>(_next).onTap,
              isNull,
              reason:
                  'Right must not offer a no-op tap at the end of a variation.',
            );
            expect(tester.widget<InkResponse>(_next).onLongPress, isNotNull);
            await tester.longPress(control);
            await tester.pumpAndSettle();
            final destination = control == _back ? 1 : 2;
            _expectSelection(
              tester,
              find.byKey(ValueKey('mainline-move-${destination - 1}')),
              session.positions[destination],
            );
            await _tap(tester, _next);
            _expectSelection(
              tester,
              find.byKey(ValueKey('mainline-move-$destination')),
              session.positions[destination + 1],
            );
            // On the main line, the same holds still go to game endpoints.
            await tester.longPress(_next);
            await tester.pumpAndSettle();
            _expectSelection(
              tester,
              find.byKey(const ValueKey('mainline-move-3')),
              session.positions[4],
            );
            expect(tester.widget<InkResponse>(_next).onTap, isNull);
            expect(tester.widget<InkResponse>(_next).onLongPress, isNull);
            await tester.longPress(_back);
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<cg.Chessboard>(find.byType(cg.Chessboard))
                  .controller
                  .fen,
              _canonical(session.positions.first),
            );
            expect(tester.widget<InkResponse>(_back).onTap, isNull);
            if (persistent) {
              final saved = (await ActiveSessionStore.load())!;
              final tree = (saved['variations'] as List).single as Map;
              expect(
                RecordedVariation.fromJson(Map<String, dynamic>.from(tree))
                    .toJson(),
                root.toJson(),
              );
            }
          },
        );
      }
    }
  }

  testWidgets(
    'hold exits a root alternative even when it is longer than the main line',
    (tester) async {
      final session = AnalysisSession.fromPgn('1. e4 (1. d4 d5 2. c4 e6) *');
      final alternative = PgnVariationExporter.parseTree(session.pgn)[1];
      await _open(tester, session, _fen(alternative, 4));
      await tester.longPress(_next);
      await tester.pumpAndSettle();
      expect(
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).controller.fen,
        _canonical(session.positions[1]),
      );
      expect(tester.widget<InkResponse>(_next).onTap, isNull);
      _expectSelection(
        tester,
        find.byKey(const ValueKey('mainline-move-0')),
        session.positions[1],
      );
    },
  );

  testWidgets(
    'hold exits a branch from its first move without jumping to the game start',
    (tester) async {
      final session = AnalysisSession.fromPgn(
        '1. e4 e5 2. Nf3 (2. Bc4 Nc6) Nc6 *',
      );
      final branch = PgnVariationExporter.parseTree(session.pgn)
          .single
          .children
          .single;
      await _open(tester, session, _fen(branch, 1));
      await tester.longPress(_back);
      await tester.pumpAndSettle();
      _expectSelection(
        tester,
        find.byKey(const ValueKey('mainline-move-1')),
        session.positions[2],
      );
    },
  );

  testWidgets(
    'exit does not wait for engines and ignores late variation results',
    (tester) async {
      final session = AnalysisSession.fromPgn(
        '1. e4 e5 (1... c5 2. Nf3) 2. Nc3 *',
      );
      final branch = PgnVariationExporter.parseTree(session.pgn)
          .single
          .children
          .single;
      final pending = <Completer<StockfishReview>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: session,
            initialCurrentFen: _fen(branch, 1),
            maiaElo: 1600,
            evaluator: (fen) {
              if (fen == _fen(branch, 1) || fen == _fen(branch, 2)) {
                final completer = Completer<StockfishReview>();
                pending.add(completer);
                return completer.future;
              }
              return Future.value(const StockfishReview(125, ''));
            },
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(_next);
      // A second tap before rendering still invokes the old enabled callback.
      // It must neither restart the engine nor reset the unchanged board again.
      final callsAtEnd = pending.length;
      await tester.tap(_next);
      expect(pending.length, callsAtEnd);
      await tester.pump();
      expect(
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).controller.fen,
        _canonical(_fen(branch, 2)),
      );
      expect(tester.widget<InkResponse>(_next).onTap, isNull);
      await tester.longPress(_next);
      await tester.pump();
      _expectSelection(
        tester,
        find.byKey(const ValueKey('mainline-move-1')),
        session.positions[2],
      );
      for (final completer in pending) {
        completer.complete(const StockfishReview(999, ''));
      }
      await tester.pumpAndSettle();
      _expectSelection(
        tester,
        find.byKey(const ValueKey('mainline-move-1')),
        session.positions[2],
      );
      expect(find.text('+10.0'), findsNothing);
      expect(find.text('+1.3'), findsWidgets);
    },
  );

  testWidgets(
    'holding Right from a continuation beyond the game stops at the final main-line position',
    (tester) async {
      final session = AnalysisSession.fromPgn('1. e4 e5 2. Nf3 *');
      await _open(tester, session, session.positions.last, persistent: false);
      tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
        dc.NormalMove.fromUci('b8c6'),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<InkResponse>(_next).onTap, isNull);
      expect(tester.widget<InkResponse>(_next).onLongPress, isNotNull);
      await tester.longPress(_next);
      await tester.pumpAndSettle();
      _expectSelection(
        tester,
        find.byKey(const ValueKey('mainline-move-2')),
        session.positions.last,
      );
      expect(tester.widget<InkResponse>(_next).onTap, isNull);
      expect(tester.widget<InkResponse>(_next).onLongPress, isNull);
    },
  );

  for (final persistent in [true, false]) {
    for (final whiteBranch in [true, false]) {
      for (final longVariation in [false, true]) {
        testWidgets(
          'Hold Right advances one main-line move independent of variation length (saved=$persistent, white=$whiteBranch, long=$longVariation)',
          (tester) async {
            final moves = whiteBranch
                ? (longVariation ? 'Bc4 Bc5 3. d3 d6' : 'Bc4')
                : (longVariation ? 'c5 2. Nf3 d6 3. d4 cxd4' : 'c5');
            final pgn = whiteBranch
                ? '1. e4 e5 2. Nf3 (2. $moves) Nc6 3. Bb5 a6 *'
                : '1. e4 e5 (1... $moves) 2. Nf3 Nc6 3. Bb5 a6 *';
            final session = AnalysisSession.fromPgn(pgn);
            final branch = PgnVariationExporter.parseTree(pgn)
                .single
                .children
                .single;
            final destination = branch.basePly + 1;
            await _open(
              tester,
              session,
              _fen(branch, branch.sanMoves.length),
              persistent: persistent,
            );
            await tester.longPress(_next);
            await tester.pumpAndSettle();
            _expectSelection(
              tester,
              find.byKey(ValueKey('mainline-move-${destination - 1}')),
              session.positions[destination],
            );
            // Selecting the FIRST branch move must produce the same exit.
            await _tap(tester, _move(branch.sanMoves.first));
            await tester.longPress(_next);
            await tester.pumpAndSettle();
            _expectSelection(
              tester,
              find.byKey(ValueKey('mainline-move-${destination - 1}')),
              session.positions[destination],
            );
            await _tap(tester, _back);
            _expectSelection(
              tester,
              find.byKey(ValueKey('mainline-move-${branch.basePly - 1}')),
              session.positions[branch.basePly],
            );
          },
        );
      }
    }
  }
}
