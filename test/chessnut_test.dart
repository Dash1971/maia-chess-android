import 'dart:async';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _startingPayload = <int>[
  0x58,
  0x23,
  0x31,
  0x85,
  0x44,
  0x44,
  0x44,
  0x44,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x77,
  0x77,
  0x77,
  0x77,
  0xa6,
  0xc9,
  0x9b,
  0x6a,
];

Map<String, String> _after(chess.Chess game, String uci) {
  final next = chess.Chess.fromFEN(game.fen);
  final move = next
      .moves({'asObjects': true})
      .cast<chess.Move>()
      .singleWhere((candidate) => MaiaEncoding.uci(candidate) == uci);
  expect(next.move(move), isTrue);
  return ChessnutProtocol.pieceMapFromFen(next.fen);
}

class _FakeElectronicBoard implements ElectronicBoardTransport {
  final StreamController<ElectronicBoardEvent> _events =
      StreamController<ElectronicBoardEvent>.broadcast(sync: true);
  final List<List<String>> ledCommands = [];
  final List<List<int>> beepCommands = [];
  bool connected = false;
  Completer<void>? beepGate;
  bool failLeds = false;
  int connectCalls = 0;
  Map<String, String>? nextConnectPosition;

  @override
  Stream<ElectronicBoardEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    connectCalls++;
    connected = true;
    _events.add(
      const ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.ready,
        message: 'Chessnut Go is ready.',
        deviceName: 'Chessnut Go',
      ),
    );
    position(
      nextConnectPosition ??
          ChessnutProtocol.pieceMapFromFen(chess.Chess.DEFAULT_POSITION),
    );
    nextConnectPosition = null;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    _events.add(
      const ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.disconnected,
        message: 'Chessnut Go is disconnected.',
      ),
    );
  }

  @override
  Future<void> setLeds(Iterable<String> squares) async {
    if (failLeds) throw PlatformException(code: 'write_failed');
    ledCommands.add(squares.toList(growable: false));
  }

  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) async {
    beepCommands.add([frequencyHz, durationMs]);
    await beepGate?.future;
  }

  void position(Map<String, String> pieces) {
    _events.add(ElectronicBoardEvent(type: 'position', position: pieces));
  }

  void ready(Map<String, String> pieces) {
    connected = true;
    _events.add(
      const ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.ready,
        message: 'Chessnut Go is ready.',
        deviceName: 'Chessnut Go',
      ),
    );
    position(pieces);
  }

  Future<void> close() => _events.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodes Chessnut starting-position payload', () {
    final pieces = ChessnutProtocol.decodePosition(_startingPayload);

    expect(pieces, hasLength(32));
    expect(pieces['a1'], 'R');
    expect(pieces['e1'], 'K');
    expect(pieces['d8'], 'q');
    expect(pieces['h8'], 'r');
  });

  test('decodes a full Chessnut notification', () {
    final pieces = ChessnutProtocol.decodePosition([
      0x01,
      0x24,
      ..._startingPayload,
      0x00,
      0x00,
    ]);

    expect(pieces['e1'], 'K');
    expect(pieces['e8'], 'k');
  });

  test('rejects malformed Chessnut payloads', () {
    expect(
      () => ChessnutProtocol.decodePosition(const [0x01, 0x24]),
      throwsFormatException,
    );
  });

  test('encodes move LEDs in Chessnut row order', () {
    expect(ChessnutProtocol.encodeLedCommand(const ['e2', 'e4']), const [
      0x0a,
      0x08,
      0,
      0,
      0,
      0,
      0x08,
      0,
      0x08,
      0,
    ]);
  });

  test('encodes the same default buzzer command as the Chessnut CLI', () {
    expect(ChessnutProtocol.encodeBeepCommand(), const [
      0x0b,
      0x04,
      0x03,
      0xe8,
      0x00,
      0xc8,
    ]);
    expect(
      () => ChessnutProtocol.encodeBeepCommand(frequencyHz: 0),
      throwsArgumentError,
    );
    expect(
      () => ChessnutProtocol.encodeBeepCommand(durationMs: 0),
      throwsArgumentError,
    );
  });

  test('parses FEN piece placement', () {
    final pieces = ChessnutProtocol.pieceMapFromFen(
      chess.Chess.DEFAULT_POSITION,
    );

    expect(pieces, hasLength(32));
    expect(pieces['a2'], 'P');
    expect(pieces['g8'], 'n');
  });

  test('strictly infers quiet moves and captures', () {
    final game = chess.Chess();
    expect(ChessnutProtocol.inferLegalMove(game, _after(game, 'e2e4')), 'e2e4');
    game.move('e4');
    game.move('d5');
    expect(ChessnutProtocol.inferLegalMove(game, _after(game, 'e4d5')), 'e4d5');
  });

  test('strictly infers castling only after king and rook are placed', () {
    final game = chess.Chess.fromFEN(
      'rnbqkbnr/pppppppp/8/8/8/5N2/PPPPBPPP/RNBQK2R w KQkq - 2 3',
    );
    expect(ChessnutProtocol.inferLegalMove(game, _after(game, 'e1g1')), 'e1g1');

    final partial =
        Map<String, String>.of(ChessnutProtocol.pieceMapFromFen(game.fen))
          ..remove('e1')
          ..remove('h1')
          ..['f1'] = 'R';
    expect(ChessnutProtocol.inferLegalMove(game, partial), isNull);
  });

  test('strictly infers en passant and promotion piece identity', () {
    final enPassant = chess.Chess();
    for (final san in const ['e4', 'a6', 'e5', 'd5']) {
      expect(enPassant.move(san), isTrue);
    }
    expect(
      ChessnutProtocol.inferLegalMove(enPassant, _after(enPassant, 'e5d6')),
      'e5d6',
    );

    final promotion = chess.Chess.fromFEN('8/P7/8/8/8/8/7k/4K3 w - - 0 1');
    expect(
      ChessnutProtocol.inferLegalMove(promotion, _after(promotion, 'a7a8q')),
      'a7a8q',
    );
  });

  test('does not flag a lifted piece as a complete move attempt', () {
    final game = chess.Chess();
    final lifted = Map<String, String>.of(
      ChessnutProtocol.pieceMapFromFen(game.fen),
    )..remove('e2');
    expect(
      ChessnutProtocol.looksLikeCompleteMoveAttempt(game, lifted),
      isFalse,
    );

    final illegalPlacement = Map<String, String>.of(lifted)..['e5'] = 'P';
    expect(
      ChessnutProtocol.looksLikeCompleteMoveAttempt(game, illegalPlacement),
      isTrue,
    );
  });

  test('reports every square that differs from the expected position', () {
    expect(
      ChessnutProtocol.mismatchSquares(const {'e4': 'P'}, const {'e2': 'P'}),
      const ['e2', 'e4'],
    );
  });

  testWidgets('physical move drives Maia and LEDs gate the next turn', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final board = _FakeElectronicBoard();
    final policy = Float32List(4352)..fillRange(0, 4352, -100);
    policy[MaiaEncoding.moveIndex('e7e5', true)] = 100;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => policy,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toggle = find.byKey(const ValueKey('chessnut-go-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(board.connected, isTrue);

    final start = find.widgetWithText(FilledButton, 'Start game');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('chessnut-status-banner')),
      findsOneWidget,
    );

    final game = chess.Chess();
    board.position(_after(game, 'e2e4'));
    await tester.pump();
    await tester.pump();
    expect(
      board.ledCommands.any(
        (command) => command.toSet().containsAll(const {'e7', 'e5'}),
      ),
      isTrue,
    );
    expect(find.text('e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);

    final litMoveCommands = board.ledCommands
        .where((command) => command.toSet().containsAll(const {'e7', 'e5'}))
        .length;
    await tester.pump(const Duration(seconds: 1));
    expect(
      board.ledCommands
          .where((command) => command.toSet().containsAll(const {'e7', 'e5'}))
          .length,
      litMoveCommands,
      reason: 'Pending LEDs must not be flooded with immediate retries.',
    );
    await tester.pump(const Duration(milliseconds: 1100));
    expect(
      board.ledCommands
          .where((command) => command.toSet().containsAll(const {'e7', 'e5'}))
          .length,
      greaterThan(litMoveCommands),
    );

    game.move('e4');
    game.move('e5');
    board.position(ChessnutProtocol.pieceMapFromFen(game.fen));
    await tester.pump();
    expect(board.ledCommands.last, isEmpty);
    expect(find.text('Your move on Chessnut Go.'), findsOneWidget);
    final clearIndex = board.ledCommands.lastIndexWhere(
      (command) => command.isEmpty,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(
      board.ledCommands
          .skip(clearIndex + 1)
          .every((command) => command.isEmpty),
      isTrue,
      reason: 'A cancelled LED burst must not relight a completed move.',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
  });

  testWidgets('inline reconnect rescans without losing the live game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final board = _FakeElectronicBoard();
    final policy = Float32List(4352)..fillRange(0, 4352, -100);
    policy[MaiaEncoding.moveIndex('e7e5', true)] = 100;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => policy,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('chessnut-go-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final start = find.widgetWithText(FilledButton, 'Start game');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();

    final afterE4 = _after(chess.Chess(), 'e2e4');
    board.position(afterE4);
    await tester.pump();
    await tester.pump();
    expect(find.text('e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);

    await board.disconnect();
    await tester.pump();
    final reconnect = find.byKey(const ValueKey('chessnut-inline-reconnect'));
    expect(reconnect, findsOneWidget);
    board.nextConnectPosition = afterE4;
    await tester.tap(reconnect);
    await tester.pump();
    await tester.pump();

    expect(board.connectCalls, 2);
    expect(find.text('e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
    expect(board.ledCommands.last.toSet(), containsAll(const {'e7', 'e5'}));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
  });

  testWidgets(
    'completed illegal moves beep once while piece lifts stay silent',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final board = _FakeElectronicBoard();
      final pendingMaia = Completer<Float32List>();
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            electronicBoardTransport: board,
            maiaEvaluator: (_, _) => pendingMaia.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('chessnut-go-toggle')),
      );
      await tester.tap(find.byKey(const ValueKey('chessnut-go-toggle')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Start game'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pump();

      final game = chess.Chess();
      final lifted = Map<String, String>.of(
        ChessnutProtocol.pieceMapFromFen(game.fen),
      )..remove('e2');
      board.position(lifted);
      await tester.pump();
      expect(board.beepCommands, isEmpty);

      final illegal = Map<String, String>.of(lifted)..['e5'] = 'P';
      board.position(illegal);
      await tester.pump(const Duration(milliseconds: 250));
      expect(board.beepCommands, const [
        [1000, 200],
      ]);

      board.position(illegal);
      await tester.pump(const Duration(milliseconds: 250));
      expect(board.beepCommands, hasLength(1));

      board.position(lifted);
      await tester.pump();
      board.position(illegal);
      await tester.pump(const Duration(milliseconds: 250));
      expect(board.beepCommands, hasLength(2));

      await tester.pumpWidget(const SizedBox.shrink());
      pendingMaia.complete(Float32List(4352));
      await tester.pump();
      await board.close();
    },
  );

  testWidgets('the persistent Chessnut board-sounds setting can mute alerts', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'chessnutBoardSounds': false});
    final board = _FakeElectronicBoard();
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => Float32List(4352),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('chessnut-go-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('chessnut-go-toggle')));
    await tester.pumpAndSettle();
    final sounds = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('chessnut-sounds-toggle')),
    );
    expect(sounds.value, isFalse);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Start game'));
    await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
    await tester.pump();
    final illegal =
        Map<String, String>.of(
            ChessnutProtocol.pieceMapFromFen(chess.Chess.DEFAULT_POSITION),
          )
          ..remove('e2')
          ..['e5'] = 'P';
    board.position(illegal);
    await tester.pump(const Duration(milliseconds: 250));
    expect(board.beepCommands, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
  });

  testWidgets('Chessnut takeback restores the physical board before play', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final board = _FakeElectronicBoard();
    final policy = Float32List(4352)..fillRange(0, 4352, -100);
    policy[MaiaEncoding.moveIndex('e7e5', true)] = 100;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => policy,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('chessnut-go-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('chessnut-go-toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Start game'));
    await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
    await tester.pump();

    final game = chess.Chess();
    final afterE4 = _after(game, 'e2e4');
    board.position(afterE4);
    await tester.pump();
    await tester.pump();
    expect(find.text('e5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Take back move'), findsOneWidget);
    await tester.tap(find.text('Take back move'));
    await tester.pump();
    expect(
      find.text('Takeback: restore the lit squares on Chessnut Go.'),
      findsOneWidget,
    );
    expect(board.ledCommands.last.toSet(), containsAll(const {'e2', 'e4'}));

    await board.disconnect();
    await tester.pump();
    board.ready(afterE4);
    await tester.pump();
    expect(board.ledCommands.last.toSet(), containsAll(const {'e2', 'e4'}));

    board.position(
      ChessnutProtocol.pieceMapFromFen(chess.Chess.DEFAULT_POSITION),
    );
    await tester.pump();
    expect(
      find.text('Takeback complete. Your move on Chessnut Go.'),
      findsOneWidget,
    );
    await tester.pump();
    final saved = await ActiveSessionStore.load();
    final variations = saved!['variations'] as List;
    expect(variations, hasLength(1));
    expect((variations.single as Map)['sanMoves'], const ['e4', 'e5']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
  });

  testWidgets('disconnect still closes the board if clearing LEDs fails', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final board = _FakeElectronicBoard();
    await tester.pumpWidget(
      MaterialApp(home: GamePage(electronicBoardTransport: board)),
    );
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('chessnut-go-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(board.connected, isTrue);
    board.failLeds = true;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(board.connected, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await board.close();
  });

  testWidgets(
    'pausing during a Maia check alert retains physical move guidance',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const pgn = '[Result "*"]\n\n1. e4 e5 2. d4 Nc6 3. Nf3 *';
      final session = AnalysisSession.fromPgn(pgn);
      await ActiveSessionStore.save({
        'type': 'game',
        'pgn': pgn,
        'playerIsWhite': true,
        'timePreset': 'unlimited',
        'clockPaused': false,
        'electronicBoard': 'chessnut-go',
      });
      final board = _FakeElectronicBoard()..beepGate = Completer<void>();
      final policy = Float32List(4352)..fillRange(0, 4352, -100);
      policy[MaiaEncoding.moveIndex('f8b4', true)] = 100;
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            electronicBoardTransport: board,
            maiaEvaluator: (_, _) async => policy,
          ),
        ),
      );
      await tester.pumpAndSettle();
      board.ready(ChessnutProtocol.pieceMapFromFen(session.positions.last));
      await tester.pump();
      expect(board.beepCommands, hasLength(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final saved = await ActiveSessionStore.load();
      expect(saved!['pendingPhysicalMaiaMove'], 'f8b4');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(board.ledCommands.last.toSet(), containsAll(['f8', 'b4']));
      board.beepGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(seconds: 3));
      expect(board.ledCommands.last.toSet(), containsAll(['f8', 'b4']));
      await tester.pumpWidget(const SizedBox.shrink());
      await board.close();
    },
  );

  testWidgets('a delayed check alert cannot update a disposed game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const pgn = '[Result "*"]\n\n1. e4 e5 2. Bc4 Nc6 *';
    final session = AnalysisSession.fromPgn(pgn);
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': pgn,
      'playerIsWhite': true,
      'timePreset': 'unlimited',
      'clockPaused': false,
      'electronicBoard': 'chessnut-go',
    });
    final board = _FakeElectronicBoard()..beepGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => Float32List(4352),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = chess.Chess.fromFEN(session.positions.last);
    board.ready(ChessnutProtocol.pieceMapFromFen(before.fen));
    await tester.pump();
    board.position(_after(before, 'c4f7'));
    await tester.pump();
    expect(board.beepCommands, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    board.beepGate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    final preferences = await SharedPreferences.getInstance();
    final diagnostics = preferences.getStringList('diagnosticEntriesV1') ?? [];
    expect(
      diagnostics.join('\n'),
      isNot(contains('setState() called after dispose')),
    );
    await board.close();
  });

  testWidgets('a physical human move that gives check sounds the board', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const pgn = '''
[Event "Mobile Maia Game"]
[Result "*"]

1. e4 e5 2. Bc4 Nc6 *
''';
    final session = AnalysisSession.fromPgn(pgn);
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': pgn,
      'playerIsWhite': true,
      'timePreset': 'unlimited',
      'clockPaused': false,
      'electronicBoard': 'chessnut-go',
    });
    final board = _FakeElectronicBoard();
    final pendingMaia = Completer<Float32List>();
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) => pendingMaia.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final beforeCheck = chess.Chess.fromFEN(session.positions.last);
    board.ready(ChessnutProtocol.pieceMapFromFen(beforeCheck.fen));
    await tester.pump();
    board.position(_after(beforeCheck, 'c4f7'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(board.beepCommands, const [
      [1000, 200],
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    pendingMaia.complete(Float32List(4352));
    await tester.pump();
    await board.close();
  });

  testWidgets('Chessnut checkmate records and displays the winning result', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const pgn = '''
[Event "Mobile Maia Game"]
[Site "Mobile Maia"]
[Date "2026.09.06"]
[Round "-"]
[White "Player"]
[Black "Maia-3 79M (1600)"]
[Result "*"]

1. b4 e5 2. Bb2 d6 3. c4 Nf6 4. Nc3 Be7 5. e3 O-O 6. Nf3 Bg4
7. Be2 Nc6 8. O-O Nxb4 9. Qb3 a5 10. a3 Nc6 11. Qxb7 Qd7 12. Qb3 Rfb8
13. Qc2 Bf5 14. Bd3 Bxd3 15. Qxd3 Rxb2 16. Nd5 Nxd5 17. cxd5 Nd8
18. h4 Rab8 19. Ng5 Bxg5 20. hxg5 Qb5 21. Qf5 Qxd5 22. g6 hxg6
23. g3 gxf5 24. f4 Rxd2 25. Rf2 Rxf2 26. Rd1 *
''';
    final session = AnalysisSession.fromPgn(pgn);
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': pgn,
      'playerIsWhite': true,
      'timePreset': 'unlimited',
      'clockPaused': false,
      'electronicBoard': 'chessnut-go',
    });
    final board = _FakeElectronicBoard();
    final policy = Float32List(4352)..fillRange(0, 4352, -100);
    policy[MaiaEncoding.moveIndex('d5g2', true)] = 100;

    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => policy,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final beforeMate = chess.Chess.fromFEN(session.positions.last);
    board.ready(ChessnutProtocol.pieceMapFromFen(beforeMate.fen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      board.ledCommands.any(
        (command) => command.toSet().containsAll(const {'d5', 'g2'}),
      ),
      isTrue,
    );
    expect(board.beepCommands, const [
      [1000, 200],
      [1000, 200],
    ]);

    expect(beforeMate.move('Qg2#'), isTrue);
    board.position(ChessnutProtocol.pieceMapFromFen(beforeMate.fen));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Black is victorious'), findsOneWidget);
    expect(find.text('The game is a draw'), findsNothing);
    expect(find.text('Checkmate — Maia wins.'), findsOneWidget);
    final saved = await ActiveSessionStore.load();
    expect(saved!['pgn'], contains('[Result "0-1"]'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
  });

  testWidgets('a physical human checkmate sounds two distinct alerts', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const pgn = '''
[Event "Mobile Maia Game"]
[Result "*"]

1. f3 e5 2. g4 *
''';
    final session = AnalysisSession.fromPgn(pgn);
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': pgn,
      'playerIsWhite': false,
      'timePreset': 'unlimited',
      'clockPaused': false,
      'electronicBoard': 'chessnut-go',
    });
    final board = _FakeElectronicBoard();

    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => Float32List(4352),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final beforeMate = chess.Chess.fromFEN(session.positions.last);
    board.ready(ChessnutProtocol.pieceMapFromFen(beforeMate.fen));
    await tester.pump();
    board.position(_after(beforeMate, 'd8h4'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(board.beepCommands, const [
      [1000, 200],
      [1000, 200],
    ]);
    expect(find.text('Checkmate — you win!'), findsOneWidget);
    final saved = await ActiveSessionStore.load();
    expect(saved!['pgn'], contains('[Result "0-1"]'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
  });

  testWidgets('restored Rxe1 checkmate repairs a stale unfinished result', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const pgn = '''
[Event "Mobile Maia Game"]
[Site "Mobile Maia"]
[SetUp "1"]
[FEN "8/8/8/8/8/6k1/4r3/4R1K1 b - - 0 1"]
[White "Player"]
[Black "Maia-3 79M (1600)"]
[Result "*"]

1... Rxe1# *
''';
    final session = AnalysisSession.fromPgn(pgn);
    expect(session.sanMoves, const ['Rxe1#']);
    expect(chess.Chess.fromFEN(session.positions.last).in_checkmate, isTrue);
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': pgn,
      'playerIsWhite': true,
      'timePreset': 'unlimited',
      'clockPaused': false,
      'electronicBoard': 'chessnut-go',
    });

    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();

    expect(find.text('Black is victorious'), findsOneWidget);
    expect(find.text('The game is a draw'), findsNothing);
    final saved = await ActiveSessionStore.load();
    expect(saved!['pgn'], contains('[Result "0-1"]'));
  });

  testWidgets('unlimited mobile games keep the screen awake', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final values = <bool>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(maiaEngineChannel, (call) async {
      if (call.method == 'setKeepScreenOn') {
        values.add(call.arguments['enabled'] as bool);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(maiaEngineChannel, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: GamePage(
          startingFen: chess.Chess.DEFAULT_POSITION,
          startingSide: PlayerSide.white,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(values, contains(true));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(values.last, isFalse);
  });
}
