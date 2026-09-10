import 'dart:async';
import 'dart:typed_data';

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/electronic_board.dart';

Map<String, Object?> savedGame({
  String pgn = '1. e4 e5 *',
  Map<String, Object?> extra = const {},
}) => {
  'type': 'game',
  'recentState': 'incomplete',
  'pgn': pgn,
  'playerIsWhite': true,
  'electronicBoard': 'chessnut-go',
  'timePreset': 'unlimited',
  'elo': 1700,
  'clockPaused': true,
  ...extra,
};

cg.Chessboard boardWidget(WidgetTester tester) =>
    tester.widget<cg.Chessboard>(find.byType(cg.Chessboard));

Float32List policy(String uci, {bool black = true}) =>
    Float32List(4352)..[MaiaEncoding.moveIndex(uci, black)] = 100;

Future<void> mountGame(
  WidgetTester tester,
  SimulatedElectronicBoard board, {
  Future<Float32List> Function(List<String>, int)? evaluator,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        electronicBoardTransport: board,
        maiaEvaluator: evaluator ?? (_, _) async => policy('b8c6'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> playInApp(WidgetTester tester) async {
  await tester.tap(find.text('Play in app'));
  await tester.pumpAndSettle();
}

Future<void> disposeGame(
  WidgetTester tester,
  SimulatedElectronicBoard board,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await board.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null),
  );

  for (final (name, pgn, result) in [
    ('checkmate', '1. f3 e5 2. g4 Qh4# 0-1', null),
    ('resignation', '[Result "0-1"]\n1. e4 e5 0-1', '0-1'),
    ('agreed draw', '[Result "1/2-1/2"]\n1. e4 e5 1/2-1/2', '1/2-1/2'),
    ('legacy PGN result', '[Result "1-0"]\n1. e4 e5 1-0', null),
  ]) {
    testWidgets('completed $name restores without Chessnut mode', (
      tester,
    ) async {
      final board = SimulatedElectronicBoard();
      await ActiveSessionStore.save(
        savedGame(
          pgn: pgn,
          extra: {
            'recentState': 'completed',
            'forcedResult': result,
            'pendingPhysicalMaiaMove': 'd8h4',
            'chessnutTakebackRestore': true,
          },
        ),
      );
      await mountGame(tester, board);
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('game-conclusion-dialog')),
        findsOneWidget,
      );
      expect(board.connects, 0);
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-home-button')));
      await tester.pumpAndSettle();
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('chessnut-go-toggle')),
      );
      expect(toggle.value, isFalse);
      await disposeGame(tester, board);
    });
  }

  testWidgets(
    'saved board game can continue on screen and remembers the choice',
    (tester) async {
      final board = SimulatedElectronicBoard();
      await ActiveSessionStore.save(savedGame(extra: {'flipped': true}));
      await mountGame(tester, board);
      final fen = boardWidget(tester).controller.fen;
      expect(find.text('Reconnect'), findsOneWidget);
      expect(
        boardWidget(tester).controller.game.playerSide,
        cg.PlayerSide.none,
      );
      await playInApp(tester);
      expect(boardWidget(tester).controller.fen, fen);
      expect(
        boardWidget(tester).controller.game.playerSide,
        cg.PlayerSide.white,
      );
      final saved = (await ActiveSessionStore.load())!;
      expect(saved['electronicBoard'], isNull);
      expect(saved['pendingPhysicalMaiaMove'], isNull);
      expect(saved['timePreset'], 'unlimited');
      expect(saved['elo'], 1700);
      expect(saved['flipped'], isTrue);
      expect(saved['recentState'], 'incomplete');
      boardWidget(tester).onMove!(dc.NormalMove.fromUci('g1f3'));
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['uciMoves'], [
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await mountGame(tester, board);
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsNothing,
      );
      expect(
        boardWidget(tester).controller.game.playerSide,
        cg.PlayerSide.white,
      );
      expect(board.connects, 0);
      await disposeGame(tester, board);
    },
  );

  testWidgets('reconnect remains available without switching the saved game', (
    tester,
  ) async {
    final board = SimulatedElectronicBoard();
    final game = savedGame();
    board.connectFen = AnalysisSession.fromPgn(game['pgn']! as String)
        .positions
        .last;
    await ActiveSessionStore.save(game);
    await mountGame(tester, board);
    await tester.tap(find.byKey(const ValueKey('chessnut-inline-reconnect')));
    await tester.pumpAndSettle();
    expect(board.connects, 1);
    expect(boardWidget(tester).controller.game.playerSide, cg.PlayerSide.none);
    expect(find.text('Your move on Chessnut Go.'), findsOneWidget);
    board.status(ElectronicBoardConnectionState.disconnected);
    await tester.pumpAndSettle();
    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.text('Play in app'), findsOneWidget);
    await playInApp(tester);
    expect(boardWidget(tester).controller.game.playerSide, cg.PlayerSide.white);
    await disposeGame(tester, board);
  });
  Future<void> openBoardPanel(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('chessnut-status-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('connected board can be left before connection is lost', (
    tester,
  ) async {
    final board = SimulatedElectronicBoard();
    await ActiveSessionStore.save(savedGame());
    await mountGame(tester, board);
    board.connectFen = boardWidget(tester).controller.fen;
    await tester.tap(find.text('Reconnect'));
    await tester.pumpAndSettle();
    await openBoardPanel(tester);
    expect(find.text('Disconnect'), findsOneWidget);
    await playInApp(tester);
    expect(board.disconnects, 1);
    expect(boardWidget(tester).controller.interactive, isTrue);
    await disposeGame(tester, board);
  });

  for (final failDisconnect in [false, true]) {
    testWidgets(
      'switch during reconnect ignores late events; disconnect failure=$failDisconnect',
      (tester) async {
        final board = SimulatedElectronicBoard();
        final connect = board.connectGate = Completer<void>();
        final disconnect = board.disconnectGate = Completer<void>();
        await ActiveSessionStore.save(savedGame());
        await mountGame(tester, board);
        final fen = boardWidget(tester).controller.fen;
        await tester.tap(find.text('Reconnect'));
        await tester.pump();
        expect(find.text('Connecting to Chessnut Go…'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const ValueKey('chessnut-inline-reconnect')),
              )
              .onPressed,
          isNull,
        );
        await playInApp(tester);
        expect(boardWidget(tester).controller.interactive, isTrue);
        expect((await ActiveSessionStore.load())!['electronicBoard'], isNull);
        connect.complete();
        await tester.pump();
        board.controller.addError(PlatformException(code: 'late-error'));
        if (failDisconnect) {
          disconnect.completeError(
            PlatformException(code: 'disconnect_failed'),
          );
        } else {
          // An absent completion must time out without blocking on-screen moves.
          await tester.pump(const Duration(seconds: 3));
          disconnect.complete();
        }
        await tester.pumpAndSettle();
        expect(boardWidget(tester).controller.fen, fen);
        expect(
          find.byKey(const ValueKey('chessnut-status-banner')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await disposeGame(tester, board);
      },
    );
  }

  testWidgets(
    'switch cancels an obsolete Maia reply and applies exactly one current reply',
    (tester) async {
      final board = SimulatedElectronicBoard();
      final replies = <Completer<Float32List>>[];
      await ActiveSessionStore.save(savedGame(pgn: '1. e4 *'));
      await mountGame(
        tester,
        board,
        evaluator: (_, _) {
          final reply = Completer<Float32List>();
          replies.add(reply);
          return reply.future;
        },
      );
      board.connectFen = boardWidget(tester).controller.fen;
      await tester.tap(find.text('Reconnect'));
      await tester.pumpAndSettle();
      expect(replies, hasLength(1));
      board.status(ElectronicBoardConnectionState.disconnected);
      await tester.pump();
      await playInApp(tester);
      expect(replies, hasLength(2));
      replies[1].complete(policy('e7e5'));
      await tester.pumpAndSettle();
      replies[0].complete(policy('c7c5'));
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['uciMoves'], ['e2e4', 'e7e5']);
      expect(boardWidget(tester).controller.interactive, isTrue);
      expect(
        (await ActiveSessionStore.load())!['pendingPhysicalMaiaMove'],
        isNull,
      );
      await disposeGame(tester, board);
    },
  );

  for (final takeback in [false, true]) {
    testWidgets(
      'switch clears ${takeback ? 'takeback' : 'pending Maia'} guidance despite a late LED write',
      (tester) async {
        final board = SimulatedElectronicBoard();
        await ActiveSessionStore.save(
          savedGame(
            extra: {
              if (takeback) 'chessnutTakebackRestore': true,
              if (!takeback) 'pendingPhysicalMaiaMove': 'e7e5',
              'variations': [
                RecordedVariation(
                  basePly: 0,
                  baseFen: AnalysisSession.start().positions.first,
                  sanMoves: ['d4'],
                ).toJson(),
              ],
            },
          ),
        );
        await mountGame(tester, board);
        final before = boardWidget(tester).controller.fen;
        board.status(ElectronicBoardConnectionState.ready);
        await tester.pump();
        final gate = board.writeGate = Completer<void>();
        // A new physical position triggers a different mismatch command.
        board.position(AnalysisSession.fromPgn('1. d4 *').positions.last);
        await tester.pump();
        expect(board.writeGate, isNull);
        await openBoardPanel(tester);
        await playInApp(tester);
        gate.complete();
        await tester.pumpAndSettle();
        final commandCount = board.leds.length;
        await tester.pump(const Duration(seconds: 5));
        expect(board.leds, hasLength(commandCount));
        final saved = (await ActiveSessionStore.load())!;
        expect(saved['uciMoves'], ['e2e4', 'e7e5']);
        expect(saved['pendingPhysicalMaiaMove'], isNull);
        expect(saved['chessnutTakebackRestore'], isNull);
        expect(saved['variations'], hasLength(1));
        expect(saved['status'], 'Your move.');
        expect(boardWidget(tester).controller.fen, before);
        expect(boardWidget(tester).controller.interactive, isTrue);
        await disposeGame(tester, board);
      },
    );
  }

  testWidgets(
    'an uncommitted physical move cannot arrive after switching input',
    (tester) async {
      final board = SimulatedElectronicBoard();
      await ActiveSessionStore.save(savedGame());
      await mountGame(tester, board);
      board.status(ElectronicBoardConnectionState.ready);
      await tester.pump();
      final gate = board.writeGate = Completer<void>();
      board.position(
        AnalysisSession.fromPgn('1. e4 e5 2. Nf3 *').positions.last,
      );
      await tester.pump();
      expect(board.writeGate, isNull);
      await openBoardPanel(tester);
      await playInApp(tester);
      gate.complete();
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['uciMoves'], ['e2e4', 'e7e5']);
      await disposeGame(tester, board);
    },
  );

  testWidgets('failed Maia turn stays retryable after switching input', (
    tester,
  ) async {
    final board = SimulatedElectronicBoard();
    var calls = 0;
    await ActiveSessionStore.save(
      savedGame(pgn: '1. e4 *', extra: {'maiaFailed': true}),
    );
    await mountGame(
      tester,
      board,
      evaluator: (_, _) async {
        calls++;
        return policy('e7e5');
      },
    );
    await playInApp(tester);
    expect(calls, 0);
    await tester.tap(find.text('Maia error. Retry'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect((await ActiveSessionStore.load())!['uciMoves'], ['e2e4', 'e7e5']);
    await disposeGame(tester, board);
  });

  testWidgets(
    'switching cancels a pending draw decision without blocking play',
    (tester) async {
      final board = SimulatedElectronicBoard();
      final draw = Completer<StockfishReview>();
      final session = AnalysisSession.fromFen('7k/8/8/8/8/8/P7/KR6 w - - 0 1');
      await ActiveSessionStore.save(savedGame(pgn: session.pgn));
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            electronicBoardTransport: board,
            drawEvaluator: (_) => draw.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      board.connectFen = session.positions.single;
      await tester.tap(find.text('Reconnect'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offer draw'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Offer draw'));
      await tester.pumpAndSettle();
      board.status(ElectronicBoardConnectionState.disconnected);
      await tester.pump();
      await playInApp(tester);
      expect(boardWidget(tester).controller.interactive, isTrue);
      draw.complete(const StockfishReview(0, ''));
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['forcedResult'], isNull);
      expect(
        find.byKey(const ValueKey('game-conclusion-dialog')),
        findsNothing,
      );
      await disposeGame(tester, board);
    },
  );
  testWidgets(
    'switching after Maia checkmate releases the physical acknowledgement gate',
    (tester) async {
      final board = SimulatedElectronicBoard();
      await ActiveSessionStore.save(savedGame(pgn: '1. f3 e5 2. g4 *'));
      await mountGame(tester, board, evaluator: (_, _) async => policy('d8h4'));
      board.connectFen = boardWidget(tester).controller.fen;
      await tester.tap(find.text('Reconnect'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        (await ActiveSessionStore.load())!['pendingPhysicalMaiaMove'],
        'd8h4',
      );
      expect(
        find.byKey(const ValueKey('game-conclusion-dialog')),
        findsNothing,
      );
      board.status(ElectronicBoardConnectionState.disconnected);
      await tester.pump();
      await playInApp(tester);
      expect(find.text('Black is victorious'), findsOneWidget);
      final saved = (await ActiveSessionStore.load())!;
      expect(saved['pendingPhysicalMaiaMove'], isNull);
      expect(saved['recentState'], 'completed');
      expect(saved['uciMoves'], ['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      await disposeGame(tester, board);
    },
  );
}
