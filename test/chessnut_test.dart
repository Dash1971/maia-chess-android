import 'dart:async';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
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
  bool connected = false;

  @override
  Stream<ElectronicBoardEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    connected = true;
    _events.add(
      const ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.ready,
        message: 'Chessnut Go is ready.',
        deviceName: 'Chessnut Go',
      ),
    );
    position(ChessnutProtocol.pieceMapFromFen(chess.Chess.DEFAULT_POSITION));
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
    ledCommands.add(squares.toList(growable: false));
  }

  void position(Map<String, String> pieces) {
    _events.add(ElectronicBoardEvent(type: 'position', position: pieces));
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

    game.move('e4');
    game.move('e5');
    board.position(ChessnutProtocol.pieceMapFromFen(game.fen));
    await tester.pump();
    expect(board.ledCommands.last, isEmpty);
    expect(find.text('Your move on Chessnut Go.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
  });
}
