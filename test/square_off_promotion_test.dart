import 'dart:async';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';

import 'board_connection_widget_test.dart' show DiscoveryBoard;
import 'fixtures/immediate_maia_preferences.dart';

class PromotionBoard extends DiscoveryBoard {
  Completer<void>? movementGate, confirmationGate;
  bool failMovement = false;
  @override
  Future<void> movePiece(String uci, String session) async {
    await super.movePiece(uci, session);
    if (movementGate case final gate?) await gate.future;
    if (failMovement) throw StateError('Test write failure');
  }

  @override
  Future<void> confirmPosition(String session) async {
    await super.confirmPosition(session);
    if (confirmationGate case final gate?) await gate.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all promotion identities survive coordinate-only wire conversion', () {
    for (final stem in ['a7a8', 'b7a8', 'h2h1', 'g2h1']) {
      for (final piece in ['q', 'r', 'b', 'n']) {
        final move = SquareOffMotorMove('$stem$piece');
        expect(move.uci, '$stem$piece');
        expect(move.coordinates, stem);
        expect(move.promotion, piece);
      }
    }
    expect(SquareOffMotorMove('e2e4').promotion, isNull);
    for (final uci in [
      'a7a8k',
      'a7a8qq',
      'a7a7q',
      'a7a1q',
      'a2a8q',
      'e2e4q',
      'x',
      'e2e2',
    ]) {
      expect(() => SquareOffMotorMove(uci), throwsFormatException);
    }
  });

  late PromotionBoard board;
  setUp(() {
    setImmediateMaiaPreferences({});
    board = PromotionBoard();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() async {
    if (board.movementGate case final gate?) {
      if (!gate.isCompleted) gate.complete();
    }
    if (board.confirmationGate case final gate?) {
      if (!gate.isCompleted) gate.complete();
    }
    await board.controller.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });
  Future<Map<String, dynamic>> saved() async =>
      (await ActiveSessionStore.load())!;
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  Future<void> launch(
    WidgetTester tester, {
    required bool whiteMaia,
    required bool capture,
    String piece = 'q',
    Locale? locale,
    double scale = 1,
    bool failPromotion = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final replies = whiteMaia
        ? (capture
              ? ['a2a4', 'a4b5', 'b5b6', 'b6b7', 'b7a8$piece']
              : ['h2h4', 'h4g5', 'g5g6', 'g6g7', 'g7g8$piece'])
        : (capture
              ? ['b7b5', 'a7a5', 'a5a4', 'a4a3', 'a3b2', 'b2a1$piece']
              : ['h7h5', 'h5g4', 'g4g3', 'g3g2', 'g2g1$piece']);
    final human = whiteMaia
        ? (capture
              ? ['b7b5', 'h7h6', 'h6h5', 'g7g6']
              : ['g7g5', 'g8f6', 'h7h6', 'h6h5'])
        : (capture
              ? ['a2a4', 'a4b5', 'h2h3', 'h3h4', 'g2g3', 'g3g4']
              : ['g2g4', 'g1f3', 'h2h3', 'h3h4', 'a2a3']);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (positions, _) async {
            final game = chess.Chess.fromFEN(positions.last);
            final move = replies.isNotEmpty
                ? replies.removeAt(0)
                : MaiaEncoding.uci(
                    game.moves({'asObjects': true}).cast<chess.Move>().first,
                  );
            expect(
              game
                  .moves({'asObjects': true})
                  .cast<chess.Move>()
                  .map(MaiaEncoding.uci),
              contains(move),
            );
            final policy = Float32List(4352)..fillRange(0, 4352, -1000);
            policy[MaiaEncoding.moveIndex(
                  move,
                  game.turn == chess.Color.BLACK,
                )] =
                1000;
            return policy;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final translations = await AppLocalizations.delegate.load(
      locale ?? const Locale('en'),
    );
    if (whiteMaia) {
      await tester.tap(find.text(translations.black).first);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-chessnut-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('home-chessnut-toggle')));
    await tester.pumpAndSettle();
    board.status(BoardKind.squareOff);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('board-confirm-setup')),
    );
    await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
    await tester.pumpAndSettle();
    final start = find.widgetWithText(FilledButton, translations.startGame);
    await tester.ensureVisible(start.first);
    await tester.tap(start.first);
    await tester.pumpAndSettle();
    for (int i = 0; i < human.length; i++) {
      if (i == human.length - 1 && (piece == 'r')) {
        board.movementGate = Completer<void>();
      }
      if (i == human.length - 1) board.failMovement = failPromotion;
      board.bytes(BoardKind.squareOff, human[i].codeUnits);
      await tester.pumpAndSettle();
    }
    expect(replies, isEmpty);
    expect((await saved())['pendingPhysicalMaiaMove'], endsWith(piece));
    if (locale != null) {
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
    }
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('board-confirm-motor')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<cg.StaticChessboard>(
            find.byKey(const ValueKey('board-promotion-position')),
          )
          .fen,
      ((await saved())['positions'] as List).last,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('board-motor-confirm')),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('board-promotion-replaced')),
    );
    await tester.tap(find.byKey(const ValueKey('board-promotion-replaced')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('board-motor-confirm')),
    );
    await tester.tap(find.byKey(const ValueKey('board-motor-confirm')));
    await tester.pumpAndSettle();
  }

  for (final whiteMaia in [true, false]) {
    for (final piece in ['q', 'r', 'b', 'n']) {
      final capture = ['q', 'b'].contains(piece);
      testWidgets('assisted $piece, Maia white=$whiteMaia, capture=$capture', (
        tester,
      ) async {
        await launch(
          tester,
          whiteMaia: whiteMaia,
          capture: capture,
          piece: piece,
        );
        final before = await saved();
        final pending = before['pendingPhysicalMaiaMove'] as String;
        expect(pending.length, 5);
        expect(board.motorMoves.last, pending.substring(0, 4));
        expect(before['uciMoves'].last, pending);
        if (board.movementGate case final gate?) {
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('board-confirm-motor')),
                )
                .onPressed,
            isNull,
          );
          gate.complete();
          await tester.pumpAndSettle();
        }
        final writes = board.motorMoves.length,
            acks = board.acknowledgements.length;
        board.bytes(BoardKind.squareOff, 'OK'.codeUnits);
        final current = chess.Chess.fromFEN(
          (before['positions'] as List).last as String,
        );
        final human = MaiaEncoding.uci(
          current.moves({'asObjects': true}).cast<chess.Move>().first,
        );
        board.bytes(BoardKind.squareOff, human.substring(0, 4).codeUnits);
        board.controller.add(
          ElectronicBoardEvent(
            type: 'position',
            boardKind: BoardKind.squareOff,
            connectionSession: 'session-selected-board',
            position: ChessnutProtocol.pieceMapFromFen(current.fen),
          ),
        );
        await tester.pumpAndSettle();
        expect((await saved())['pendingPhysicalMaiaMove'], pending);
        expect((await saved())['uciMoves'], before['uciMoves']);
        expect(board.acknowledgements.length, acks);
        if (piece == 'n') {
          await tester.tap(
            find.byKey(const ValueKey('game-previous-move-button')),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<MoveHistoryNavigator>(
                  find.byKey(const ValueKey('live-game-controls')),
                )
                .canGoForward,
            isTrue,
          );
        }
        await confirm(tester);
        expect(
          tester
              .widget<MoveHistoryNavigator>(
                find.byKey(const ValueKey('live-game-controls')),
              )
              .canGoForward,
          isFalse,
        );
        expect((await saved())['pendingPhysicalMaiaMove'], isNull);
        expect((await saved())['uciMoves'], before['uciMoves']);
        expect(board.motorMoves.length, writes);
        expect(board.confirmations, hasLength(1));
        board.bytes(BoardKind.squareOff, human.substring(0, 4).codeUnits);
        await tester.pumpAndSettle();
        expect(board.acknowledgements.length, acks + 1);
        expect(
          (await saved())['uciMoves'].length,
          (before['uciMoves'] as List).length + 2,
        );
        await dispose(tester);
      });
    }
  }

  testWidgets(
    'background invalidates confirmation; resume never repeats motor movement',
    (tester) async {
      await launch(tester, whiteMaia: true, capture: true);
      final pending = (await saved())['pendingPhysicalMaiaMove'];
      final writes = board.motorMoves.length;
      await tester.tap(find.byKey(const ValueKey('board-confirm-motor')));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('board-promotion-replaced')),
        findsNothing,
      );
      expect((await saved())['pendingPhysicalMaiaMove'], pending);
      expect(board.motorMoves.length, writes);
      await confirm(tester);
      expect((await saved())['pendingPhysicalMaiaMove'], isNull);
      expect(board.motorMoves.length, writes);
      await dispose(tester);
    },
  );
  testWidgets(
    'late confirmation after background cannot clear pending promotion',
    (tester) async {
      await launch(tester, whiteMaia: false, capture: true);
      final pending = (await saved())['pendingPhysicalMaiaMove'];
      final writes = board.motorMoves.length;
      board.confirmationGate = Completer<void>();
      await confirm(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      board.confirmationGate!.complete();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect((await saved())['pendingPhysicalMaiaMove'], pending);
      expect(board.motorMoves.length, writes);
      await confirm(tester);
      expect((await saved())['pendingPhysicalMaiaMove'], isNull);
      await dispose(tester);
    },
  );
  testWidgets(
    'disconnect while promoting retains full move and phone continuation does not replay',
    (tester) async {
      await launch(tester, whiteMaia: true, capture: false);
      final before = await saved();
      final writes = board.motorMoves.length;
      board.controller.add(
        const ElectronicBoardEvent(
          type: 'status',
          boardKind: BoardKind.squareOff,
          connectionSession: 'session-selected-board',
          connectionState: ElectronicBoardConnectionState.disconnected,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        (await saved())['pendingPhysicalMaiaMove'],
        before['pendingPhysicalMaiaMove'],
      );
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      expect((await saved())['pendingPhysicalMaiaMove'], isNull);
      expect((await saved())['uciMoves'], before['uciMoves']);
      expect(board.motorMoves.length, writes);
      await dispose(tester);
    },
  );
  testWidgets(
    'terminal promotion survives restart without automatic result or motor replay',
    (tester) async {
      await ActiveSessionStore.save({
        'type': 'game',
        'pgn': '[SetUp "1"]\n[FEN "k7/2P5/1K6/8/8/8/8/8 w - - 0 1"]\n\n1. c8=Q# 1-0',
        'electronicBoard': 'squareOff',
        'electronicBoardId': 'selected-board',
        'pendingPhysicalMaiaMove': 'c7c8q',
        'playerIsWhite': false,
        'clockPaused': true,
      });
      await tester.pumpWidget(
        MaterialApp(home: GamePage(electronicBoardTransport: board)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('game-conclusion-dialog')),
        findsNothing,
      );
      expect((await saved())['pendingPhysicalMaiaMove'], 'c7c8q');
      expect(board.motorMoves, isEmpty);
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      expect((await saved())['pendingPhysicalMaiaMove'], isNull);
      expect(board.motorMoves, isEmpty);
      expect(
        find.byKey(const ValueKey('game-conclusion-dialog')),
        findsOneWidget,
      );
      await dispose(tester);
    },
  );
  testWidgets(
    'interrupted promotion write requires phone recovery without retry',
    (tester) async {
      await launch(tester, whiteMaia: true, capture: false, piece: 'r');
      final before = await saved();
      final writes = board.motorMoves.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      board.movementGate!.complete();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        (await saved())['pendingPhysicalMaiaMove'],
        before['pendingPhysicalMaiaMove'],
      );
      expect(find.byKey(const ValueKey('board-confirm-motor')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      expect((await saved())['uciMoves'], before['uciMoves']);
      expect(board.motorMoves.length, writes);
      await dispose(tester);
    },
  );
  testWidgets(
    'failed promotion write offers phone continuation and is not retried',
    (tester) async {
      await launch(
        tester,
        whiteMaia: false,
        capture: true,
        failPromotion: true,
      );
      final before = await saved();
      final writes = board.motorMoves.length;
      expect(find.byKey(const ValueKey('board-confirm-motor')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      expect((await saved())['pendingPhysicalMaiaMove'], isNull);
      expect((await saved())['uciMoves'], before['uciMoves']);
      expect(board.motorMoves.length, writes);
      await dispose(tester);
    },
  );
  testWidgets(
    'promotion dialog can continue on phone without confirming or replaying',
    (tester) async {
      await launch(tester, whiteMaia: false, capture: true);
      final before = await saved();
      final writes = board.motorMoves.length;
      await tester.tap(find.byKey(const ValueKey('board-confirm-motor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-promotion-phone')));
      await tester.pumpAndSettle();
      expect((await saved())['pendingPhysicalMaiaMove'], isNull);
      expect((await saved())['uciMoves'], before['uciMoves']);
      expect(board.motorMoves.length, writes);
      expect(board.confirmations, isEmpty);
      await dispose(tester);
    },
  );
  testWidgets(
    'restart retains the full promotion and never enables replay or automatic confirmation',
    (tester) async {
      await launch(tester, whiteMaia: true, capture: true);
      final before = await saved();
      final writes = board.motorMoves.length;
      await dispose(tester);
      await tester.pumpWidget(
        MaterialApp(home: GamePage(electronicBoardTransport: board)),
      );
      await tester.pumpAndSettle();
      expect(
        (await saved())['pendingPhysicalMaiaMove'],
        before['pendingPhysicalMaiaMove'],
      );
      expect(board.motorMoves.length, writes);
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      expect((await saved())['uciMoves'], before['uciMoves']);
      expect(board.motorMoves.length, writes);
      await dispose(tester);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'promotion instructions ${locale.languageCode} at 320px / 200%',
      (tester) async {
        await launch(
          tester,
          whiteMaia: true,
          capture: true,
          locale: locale,
          scale: 2,
        );
        await tester.tap(find.byKey(const ValueKey('board-confirm-motor')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('board-promotion-replaced')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await dispose(tester);
      },
    );
  }
}
