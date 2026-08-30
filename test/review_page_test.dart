import 'dart:async';
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(OpeningNames.load);

  test('analysis session loads FEN and preserves setup headers', () {
    const fen = '8/8/8/8/8/4k3/8/4K3 w - - 0 1';
    final session = AnalysisSession.fromFen(fen);
    expect(session.positions, [fen]);
    expect(session.pgn, contains('[SetUp "1"]'));
    expect(session.pgn, contains('[FEN "$fen"]'));
  });

  test('analysis session reconstructs PGN position history', () {
    final session = AnalysisSession.fromPgn(
      '[Event "Test"]\n[Result "*"]\n\n1. e4 e5 2. Nf3 *',
    );
    expect(session.uciMoves, ['e2e4', 'e7e5', 'g1f3']);
    expect(session.sanMoves, ['e4', 'e5', 'Nf3']);
    expect(session.positions, hasLength(4));
  });

  test('root analysis line exports as playable PGN mainline', () {
    final exported = PgnVariationExporter.export(
      '[Event "Analysis"]\n[Result "*"]\n\n*',
      const [],
      const [
        RecordedVariation(
          basePly: 0,
          baseFen: chess.Chess.DEFAULT_POSITION,
          sanMoves: ['e4', 'e5'],
        ),
      ],
    );
    expect(exported, contains('1. e4 e5 *'));
  });

  test('root alternatives persist as sibling PGN variations', () {
    final exported = PgnVariationExporter.export(
      '[Event "Analysis"]\n[Result "*"]\n\n*',
      const [],
      const [
        RecordedVariation(
          basePly: 0,
          baseFen: chess.Chess.DEFAULT_POSITION,
          sanMoves: ['e4', 'e5'],
        ),
        RecordedVariation(
          basePly: 0,
          baseFen: chess.Chess.DEFAULT_POSITION,
          sanMoves: ['d4', 'd5'],
        ),
      ],
    );

    expect(exported, contains('1. e4 e5 (1. d4 d5) *'));
  });

  test('opening names prefer the longest known sequence', () {
    expect(
      OpeningNames.identify(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5']),
      'C60 · Ruy Lopez',
    );
  });

  test('Lichess opening data recognizes the Smith-Morra Gambit', () {
    expect(
      OpeningNames.identify(['e2e4', 'c7c5', 'd2d4', 'c5d4', 'c2c3']),
      'B21 · Sicilian Defense: Smith-Morra Gambit',
    );
  });

  test('analysis tree survives persistent JSON round trip', () async {
    SharedPreferences.setMockInitialValues({});
    const variation = RecordedVariation(
      basePly: 0,
      baseFen: chess.Chess.DEFAULT_POSITION,
      sanMoves: ['e4', 'e5'],
      children: [
        RecordedVariation(
          basePly: 1,
          baseFen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
          sanMoves: ['c5'],
        ),
      ],
    );
    await ActiveSessionStore.save({
      'type': 'analysis',
      'session': AnalysisSession.start().toJson(),
      'variations': [variation.toJson()],
      'currentFen': variation.baseFen,
      'flipped': true,
    });

    final restored = await ActiveSessionStore.load();
    final tree = RecordedVariation.fromJson(
      Map<String, dynamic>.from(
        (restored!['variations'] as List).single as Map,
      ),
    );
    expect(restored['type'], 'analysis');
    expect(restored['flipped'], isTrue);
    expect(tree.sanMoves, ['e4', 'e5']);
    expect(tree.children.single.sanMoves, ['c5']);
  });

  testWidgets('board editor uses selected piece as a Lichess-style toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BoardEditorPage(initialFen: chess.Chess.DEFAULT_POSITION),
      ),
    );

    var board = tester.widget<cg.StaticChessboard>(
      find.byType(cg.StaticChessboard),
    );
    expect(board.fen, contains('PPPPPPPP'));
    board.onTouchedSquare!(dc.Square.e2);
    await tester.pump();
    board = tester.widget<cg.StaticChessboard>(
      find.byType(cg.StaticChessboard),
    );
    expect(cg.readFen(board.fen)[dc.Square.e2], isNull);

    board.onTouchedSquare!(dc.Square.e4);
    await tester.pump();
    board = tester.widget<cg.StaticChessboard>(
      find.byType(cg.StaticChessboard),
    );
    expect(cg.readFen(board.fen)[dc.Square.e4], isNotNull);
    expect(find.text('Erase'), findsNothing);
  });
  test('PGN export preserves takebacks as recursive annotation variations', () {
    const source =
        '[Event "Mobile Maia Game"]\n[Result "*"]\n\n1. e4 e5 2. Nf3 *';
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const afterE4 =
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
    final exported = PgnVariationExporter.export(
      source,
      const ['e4', 'c5', 'Nf3'],
      const [
        RecordedVariation(
          basePly: 1,
          baseFen: afterE4,
          sanMoves: ['e5', 'Nf3'],
        ),
      ],
      mainPositions: const [start, afterE4],
    );

    expect(exported, contains('1. e4 c5 (1... e5 2. Nf3) 2. Nf3 *'));
    expect(exported, contains('[Event "Mobile Maia Game"]'));
  });

  test('PGN export keeps a nested abandoned branch attached to its parent', () {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const afterE4 =
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
    const afterE4E5 =
        'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2';
    final exported = PgnVariationExporter.export(
      '[Result "*"]\n\n*',
      const ['e4', 'd5'],
      const [
        RecordedVariation(
          basePly: 1,
          baseFen: afterE4,
          sanMoves: ['e5', 'Nf3'],
          children: [
            RecordedVariation(
              basePly: 2,
              baseFen: afterE4E5,
              sanMoves: ['Nc3'],
            ),
          ],
        ),
      ],
      mainPositions: const [start, afterE4],
    );

    expect(exported, contains('1. e4 d5 (1... e5 2. Nf3 (2. Nc3)) *'));
  });

  test('diagnostics persist exception evidence and version metadata', () async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Mobile Maia',
      packageName: 'com.dash1971.maia_chess',
      version: '1.6.6',
      buildNumber: '19',
      buildSignature: '',
    );
    await AppDiagnostics.record(
      'test-source',
      StateError('diagnostic-test-error'),
      StackTrace.fromString('diagnostic-test-stack'),
    );

    final report = await AppDiagnostics.report();
    expect(report, contains('version=1.6.6 build=19'));
    expect(report, contains('[test-source]'));
    expect(report, contains('diagnostic-test-error'));
    expect(report, contains('diagnostic-test-stack'));
  });

  testWidgets('About shows the package version instead of a hard-coded value', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Mobile Maia',
      packageName: 'com.dash1971.maia_chess',
      version: '1.6.6',
      buildNumber: '19',
      buildSignature: '',
    );
    await tester.pumpWidget(const MaiaChessApp());
    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();

    expect(find.text('1.6.6'), findsOneWidget);
    expect(find.text('1.6.4'), findsNothing);
    expect(find.text('Copy diagnostics'), findsNothing);
    expect(find.text('Licence'), findsOneWidget);
    expect(find.text('Mobile Maia source code'), findsOneWidget);
    expect(find.textContaining('AGPL-3.0-only'), findsOneWidget);
    expect(find.textContaining('without any warranty'), findsOneWidget);
    expect(find.textContaining('redistribute and modify'), findsOneWidget);
  });

  testWidgets('Copy diagnostics is in Advanced settings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaiaChessApp());
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    expect(find.text('Copy diagnostics'), findsOneWidget);
  });

  testWidgets('review page uses a fixed internally scrolling tab panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const after =
        'rnbqkbnr/pppp1ppp/8/4p3/1P6/8/P1PPPPPP/RNBQKBNR w KQkq - 0 2';
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, after],
          uciMoves: const ['b2b4'],
          sanMoves: const ['b4'],
          playerIsWhite: true,
          pgn: '1. b4',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Game review'), findsOneWidget);
    expect(find.textContaining('Variation:'), findsNothing);
    expect(find.byKey(const ValueKey('analysis-move-list')), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('b4'), findsOneWidget);
    expect(find.text('Computer analysis graph'), findsNothing);
    expect(find.byTooltip('Flip board'), findsOneWidget);
    expect(find.text('+0.0'), findsWidgets);

    await tester.tap(find.byTooltip('Computer analysis'));
    await tester.pump();
    expect(find.text('Run computer analysis'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisGraph), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('Not enough moves'), findsOneWidget);
    expect(find.text('Position 0 of 1  ·  +0.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('accuracy is computed separately for White and Black', () {
    final accuracy = GameAccuracy.fromScores(const [
      StockfishReview(0, ''),
      StockfishReview(0, ''),
      StockfishReview(300, ''),
      StockfishReview(300, ''),
    ]);

    expect(accuracy.white, 100);
    expect(accuracy.black, lessThan(50));
    expect(GameAccuracy.moveAccuracy(50, 50), 100);
    expect(GameAccuracy.moveAccuracy(40, 60), 100);
  });

  test('multi-move computer analysis produces both accuracy values', () {
    final accuracy = GameAccuracy.fromScores(const [
      StockfishReview(20, ''),
      StockfishReview(-40, ''),
      StockfishReview(-10, ''),
      StockfishReview(-180, ''),
      StockfishReview(-120, ''),
      StockfishReview(-260, ''),
      StockfishReview(-220, ''),
      StockfishReview(-500, ''),
      StockfishReview(-450, ''),
    ]);

    expect(accuracy.white, isNotNull);
    expect(accuracy.black, isNotNull);
    expect(accuracy.white, inInclusiveRange(0, 100));
    expect(accuracy.black, inInclusiveRange(0, 100));
  });

  testWidgets(
    'computer analysis evaluates the complete Analysis Board root line',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      const moves = [
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bb5',
        'a6',
        'Ba4',
        'Nf6',
        'O-O',
        'Be7',
        'Re1',
        'b5',
        'Bb3',
        'd6',
        'c3',
      ];
      final evaluated = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: const [start],
            uciMoves: const [],
            sanMoves: const [],
            playerIsWhite: true,
            pgn: '*',
            initialVariations: const [
              RecordedVariation(basePly: 0, baseFen: start, sanMoves: moves),
            ],
            onHome: () {},
            evaluator: (fen) async {
              evaluated.add(fen);
              return StockfishReview(evaluated.length * 10, 'e2e4');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Computer analysis'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
      await tester.pumpAndSettle();

      expect(find.byType(AnalysisGraph), findsOneWidget);
      expect(find.textContaining('Not enough moves'), findsNothing);
      expect(evaluated.toSet(), hasLength(16));
      expect(find.textContaining('Position 0 of 15'), findsOneWidget);

      final graph = tester.widget<AnalysisGraph>(find.byType(AnalysisGraph));
      graph.onSelected(15);
      await tester.pumpAndSettle();
      final board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      final replay = chess.Chess.fromFEN(start);
      for (final san in moves) {
        expect(replay.move(san), isTrue);
      }
      expect(board.controller.fen, replay.fen);
    },
  );

  testWidgets('evaluation bar uses signed Lichess-style score', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 300, child: EvaluationBar(evaluation: -200)),
        ),
      ),
    );

    expect(find.text('-2.0'), findsOneWidget);
  });

  testWidgets('evaluation bar preserves signed mate distance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: EvaluationBar(evaluation: 0, mate: -3),
          ),
        ),
      ),
    );

    expect(find.text('#-3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid engine bestmove cannot crash review rendering', (
    tester,
  ) async {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start],
          uciMoves: const [],
          sanMoves: const [],
          playerIsWhite: true,
          pgn: '',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, '0000'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(cg.Chessboard), findsOneWidget);
  });

  testWidgets('moving on the review board creates an analyzed variation', (
    tester,
  ) async {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    final maiaHistoryLengths = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start],
          uciMoves: const [],
          sanMoves: const [],
          playerIsWhite: true,
          pgn: '[Result "*"]\n\n*',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(20, 'e7e5'),
          maiaEvaluator: (positions, _) async {
            maiaHistoryLengths.add(positions.length);
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    var board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    board.onMove!(dc.NormalMove.fromUci('e2e4'));
    await tester.pumpAndSettle();
    board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    board.onMove!(dc.NormalMove.fromUci('e7e5'));
    await tester.pumpAndSettle();

    expect(find.text('e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
    expect(find.textContaining('Variation:'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
    final moveList = find.byKey(const ValueKey('analysis-move-list'));
    final e4Move = find.descendant(of: moveList, matching: find.text('e4'));
    await tester.ensureVisible(e4Move);
    await tester.tap(e4Move);
    await tester.pumpAndSettle();
    board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    expect(board.controller.lastMove?.uci, 'e2e4');
    expect(
      board.controller.interactive,
      isTrue,
      reason: 'Earlier variation nodes must remain playable for branching.',
    );
    final e5Move = find.descendant(of: moveList, matching: find.text('e5'));
    await tester.ensureVisible(e5Move);
    await tester.tap(e5Move);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Previous move'));
    await tester.tap(find.byTooltip('Previous move'));
    await tester.pumpAndSettle();
    board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    expect(board.controller.lastMove?.uci, 'e2e4');
    expect(maiaHistoryLengths.last, 2);
    await tester.ensureVisible(find.byTooltip('Next move'));
    await tester.tap(find.byTooltip('Next move'));
    await tester.pumpAndSettle();
    board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    expect(board.controller.lastMove?.uci, 'e7e5');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Maia engine row is stable when Maia matches Stockfish', (
    tester,
  ) async {
    const start = chess.Chess.DEFAULT_POSITION;
    final maia = Completer<String?>();
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start],
          uciMoves: const [],
          sanMoves: const [],
          playerIsWhite: true,
          pgn: '[Result "*"]\n\n*',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(20, 'e2e4'),
          maiaEvaluator: (_, _) => maia.future,
        ),
      ),
    );
    await tester.pump();

    final panel = find.byKey(const ValueKey('analysis-engine-lines'));
    final before = tester.getSize(panel);
    expect(find.byKey(const ValueKey('maia-engine-line')), findsOneWidget);
    expect(find.text('Analyzing…'), findsWidgets);

    maia.complete('e2e4');
    await tester.pumpAndSettle();

    expect(tester.getSize(panel), before);
    expect(find.text('e4 · Matches Stockfish'), findsOneWidget);
  });

  testWidgets(
    'analysis root is an unbracketed mainline and paths survive branching',
    (tester) async {
      const start = chess.Chess.DEFAULT_POSITION;
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            positions: const [start],
            uciMoves: const [],
            sanMoves: const [],
            playerIsWhite: true,
            pgn: '[Result "*"]\n\n*',
            onHome: () {},
            evaluator: (_) async => const StockfishReview(20, 'a2a3'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      board.onMove!(dc.NormalMove.fromUci('e2e4'));
      await tester.pumpAndSettle();
      board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      board.onMove!(dc.NormalMove.fromUci('e7e5'));
      await tester.pumpAndSettle();
      board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      board.onMove!(dc.NormalMove.fromUci('g1f3'));
      await tester.pumpAndSettle();

      final moveList = find.byKey(const ValueKey('analysis-move-list'));
      expect(
        find.descendant(of: moveList, matching: find.text('(')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('mainline-move-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('mainline-move-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('mainline-move-2')), findsOneWidget);

      final firstMainMove = find.byKey(const ValueKey('mainline-move-0'));
      await tester.ensureVisible(firstMainMove);
      await tester.tap(firstMainMove);
      await tester.pumpAndSettle();
      board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      board.onMove!(dc.NormalMove.fromUci('c7c5'));
      await tester.pumpAndSettle();

      final replay = chess.Chess();
      replay.move('e4');
      replay.move('e5');
      final afterE4E5 = replay.fen;
      replay.move('Nf3');
      final afterE4E5Nf3 = replay.fen;
      final sicilian = chess.Chess()
        ..move('e4')
        ..move('c5');
      String positionCore(String fen) => fen.split(' ').take(3).join(' ');

      final secondMainMove = find.byKey(const ValueKey('mainline-move-1'));
      await tester.ensureVisible(secondMainMove);
      await tester.tap(secondMainMove);
      await tester.pumpAndSettle();
      board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      expect(positionCore(board.controller.fen), positionCore(afterE4E5));

      final c5 = find.descendant(of: moveList, matching: find.text('c5'));
      await tester.ensureVisible(c5);
      await tester.tap(c5);
      await tester.pumpAndSettle();
      board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      expect(positionCore(board.controller.fen), positionCore(sicilian.fen));

      final thirdMainMove = find.byKey(const ValueKey('mainline-move-2'));
      await tester.ensureVisible(thirdMainMove);
      await tester.tap(thirdMainMove);
      await tester.pumpAndSettle();
      board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
      expect(positionCore(board.controller.fen), positionCore(afterE4E5Nf3));
    },
  );

  testWidgets('branching from a variation creates a nested clickable line', (
    tester,
  ) async {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const afterE4 =
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
    const afterE4E5 =
        'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2';
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, afterE4, afterE4E5],
          uciMoves: const ['e2e4', 'e7e5'],
          sanMoves: const ['e4', 'e5'],
          playerIsWhite: true,
          pgn: '[Result "*"]\n\n1. e4 e5 *',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, ''),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    board.onMove!(dc.NormalMove.fromUci('d2d4'));
    await tester.pumpAndSettle();
    board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    board.onMove!(dc.NormalMove.fromUci('d7d5'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('d4'));
    await tester.tap(find.text('d4'));
    await tester.pumpAndSettle();
    board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    board.onMove!(dc.NormalMove.fromUci('c7c5'));
    await tester.pumpAndSettle();

    expect(find.text('c5'), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);
    await tester.ensureVisible(find.text('c5'));
    await tester.tap(find.text('c5'));
    await tester.pumpAndSettle();
    board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    expect(board.controller.lastMove?.uci, 'c7c5');
    expect(find.textContaining('Variation:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press promotes a variation and preserves PGN branches', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn(
      '[Event "Analysis"]\n[Result "*"]\n\n1. e4 e5 2. Nf3 *',
    );
    final afterE4 = session.positions[1];
    List<RecordedVariation> saved = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: session.positions,
          uciMoves: session.uciMoves,
          sanMoves: session.sanMoves,
          playerIsWhite: true,
          pgn: session.pgn,
          initialVariations: [
            RecordedVariation(
              basePly: 1,
              baseFen: afterE4,
              sanMoves: const ['c5', 'Nf3'],
            ),
          ],
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'a2a3'),
          onSessionChanged: (_, _, variations) async {
            saved = variations;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('c5'));
    await tester.longPress(find.text('c5'));
    await tester.pumpAndSettle();
    expect(find.text('Promote variation'), findsOneWidget);
    expect(find.text('Make main line'), findsOneWidget);
    expect(find.text('Delete from here'), findsOneWidget);
    await tester.tap(find.text('Promote variation'));
    await tester.pumpAndSettle();

    expect(saved.first.sanMoves, ['e4', 'c5', 'Nf3']);
    expect(saved.first.children.single.sanMoves, ['e5', 'Nf3']);
    final exported = PgnVariationExporter.export(session.pgn, const [], saved);
    expect(exported, contains('1. e4 c5 (1... e5 2. Nf3) 2. Nf3 *'));
  });

  testWidgets('long press deletes the selected move and continuation', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn(
      '[Result "*"]\n\n1. e4 e5 2. Nf3 *',
    );
    List<RecordedVariation> saved = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: session.positions,
          uciMoves: session.uciMoves,
          sanMoves: session.sanMoves,
          playerIsWhite: true,
          pgn: session.pgn,
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'a2a3'),
          onSessionChanged: (_, _, variations) async {
            saved = variations;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('mainline-move-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete from here'));
    await tester.pumpAndSettle();

    expect(saved.single.sanMoves, ['e4']);
    expect(find.text('e5'), findsNothing);
    expect(find.text('Nf3'), findsNothing);
  });

  testWidgets('full graph awaits an evaluation already in flight', (
    tester,
  ) async {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const after = 'rnbqkbnr/pppp1ppp/8/4p3/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 2';
    final firstEvaluation = Completer<StockfishReview>();
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, after],
          uciMoves: const ['e7e5'],
          sanMoves: const ['e5'],
          playerIsWhite: true,
          pgn: '1... e5',
          onHome: () {},
          evaluator: (fen) => fen == start
              ? firstEvaluation.future
              : Future.value(const StockfishReview(-40, 'g1f3')),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Computer analysis'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    await tester.pump();
    expect(find.byType(AnalysisGraph), findsNothing);

    firstEvaluation.complete(const StockfishReview(120, 'e2e4'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(AnalysisGraph),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.painter! as AnalysisGraphPainter;
    expect(painter.scores.first.evaluation, 120);
  });

  testWidgets('graph selection is bounded by per-ply SAN labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const position = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: List.filled(100, position),
          uciMoves: List.filled(99, 'e2e4'),
          // Reproduces v1.6.6 diagnostics: graph/position data reached ply
          // 98 while the grouped SAN list only had indices 0..60.
          sanMoves: List.filled(61, 'e4'),
          playerIsWhite: true,
          pgn: '',
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Computer analysis'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    await tester.pumpAndSettle();

    final graph = find.byType(AnalysisGraph);
    final rect = tester.getRect(graph);
    await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
    await tester.pumpAndSettle();

    expect(tester.widget<AnalysisGraph>(graph).selectedPly, 61);
    expect(tester.takeException(), isNull);
  });

  testWidgets('evaluation bar renders forced mate at both extremes', (
    tester,
  ) async {
    for (final mate in const [-1, 1]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: EvaluationBar(evaluation: 0, mate: mate),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'mate=$mate');
    }
  });

  testWidgets('stepping and graph selection survive a checkmate position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const beforeMate =
        'rnbqkbnr/pppppppp/8/8/8/5P2/PPPPP1PP/RNBQKBNR b KQkq - 0 1';
    const checkmate =
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';

    Future<StockfishReview> evaluator(String fen) async => fen == checkmate
        ? const StockfishReview(0, '(none)', mate: -1)
        : const StockfishReview(25, 'e2e4');

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [start, beforeMate, checkmate],
          uciMoves: const ['f2f3', 'd8h4'],
          sanMoves: const ['f3', 'Qh4#'],
          playerIsWhite: true,
          pgn: '1. f3 e5 2. g4 Qh4#',
          onHome: () {},
          evaluator: evaluator,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('#-1'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Computer analysis'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisGraph), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(AnalysisGraph)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('every next-move transition in the reported long game renders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const pgn = '''
[Result "1/2-1/2"]

1. b4 e5 2. Bb2 Nc6 3. b5 Nd4 4. e3 Nxb5 5. Bxb5 c6 6. Be2 d6
7. Nf3 Nf6 8. c4 Be7 9. Nc3 O-O 10. O-O h6 11. a4 Nh7 12. d4 exd4
13. exd4 f5 14. d5 c5 15. Re1 f4 16. Bd3 Ng5 17. Nxg5 Bxg5 18. Ne4 f3
19. Nxg5 Qxg5 20. g3 Qh5 21. h4 Qg4 22. Be4 Bf5 23. Bxf3 Qh3
24. Qe2 Rae8 25. Qf1 Rxe1 26. Rxe1 Qxf1+ 27. Kxf1 Bd3+ 28. Be2 Bc2
29. a5 b6 30. axb6 axb6 31. Rc1 Be4 32. Ke1 Re8 33. Kd2 Bf5
34. Re1 Rf8 35. Bd3 Bg4 36. Re7 Rxf2+ 37. Kc3 Rf3 38. Rb7 Bf5
39. Rxb6 Rxd3+ 40. Kc2 Rxg3+ 41. Kc1 Rg1+ 42. Kd2 Rg2+
43. Kc1 Rg1+ 44. Kd2 Rg2+ 45. Kc1 Rg1+ 1/2-1/2
''';
    final loaded = chess.Chess()..load_pgn(pgn);
    final history = loaded.getHistory({
      'verbose': true,
    }).cast<Map<String, dynamic>>();
    final replay = chess.Chess();
    final positions = <String>[replay.fen];
    final uciMoves = <String>[];
    final sanMoves = <String>[];
    for (final move in history) {
      final from = move['from'] as String;
      final to = move['to'] as String;
      final promotion = move['promotion'] as String?;
      expect(
        replay.move({'from': from, 'to': to, 'promotion': ?promotion}),
        isTrue,
      );
      uciMoves.add('$from$to${promotion ?? ''}');
      sanMoves.add(move['san'] as String);
      positions.add(replay.fen);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: positions,
          uciMoves: uciMoves,
          sanMoves: sanMoves,
          playerIsWhite: true,
          pgn: pgn,
          onHome: () {},
          evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tabPanel = find.byKey(const ValueKey('analysis-tab-panel'));
    final initialPanelSize = tester.getSize(tabPanel);

    for (var ply = 1; ply < positions.length; ply++) {
      await tester.ensureVisible(find.byTooltip('Next move'));
      await tester.tap(find.byTooltip('Next move'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'failed at ply $ply');
    }
    final board = tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));
    expect(board.controller.fen, positions.last);
    expect(tester.getSize(tabPanel), initialPanelSize);
    expect(find.byKey(const ValueKey('analysis-move-scroll')), findsOneWidget);
  });

  test('analysis graph fills black above and white below the curve', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    AnalysisGraphPainter(
      scores: const [StockfishReview(0, ''), StockfishReview(0, '')],
      selectedPly: 0,
    ).paint(canvas, const Size(200, 100));
    final image = await recorder.endRecording().toImage(200, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    Color pixelAt(int x, int y) {
      final offset = (y * 200 + x) * 4;
      return Color.fromARGB(
        bytes!.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );
    }

    expect(pixelAt(100, 25), const Color(0xff262421));
    expect(pixelAt(100, 75), const Color(0xffeeeeee));
  });

  test('checkmate position is handled without starting Stockfish', () async {
    const checkmate =
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';
    final review = await StockfishAnalyzer.instance.evaluate(checkmate);

    expect(review.mate, -1);
    expect(review.bestMove, '(none)');
    expect(review.whiteWinningChances, lessThan(-0.99));
  });

  testWidgets('material display preserves bishop versus knight imbalance', (
    tester,
  ) async {
    const fen = '4k3/8/8/8/8/8/8/2B1K1n1 w - - 0 1';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MaterialDifference(fen: fen)),
      ),
    );

    expect(find.text('♝'), findsOneWidget);
    expect(find.text('♘'), findsOneWidget);
  });
}
