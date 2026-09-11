import 'dart:async';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Completer<void>? nextClearGate;
  Completer<void>? nextWriteGate;
  Future<void> _writeTail = Future<void>.value();
  Duration writeGap = Duration.zero;

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
    final command = squares.toList(growable: false);
    final gate = nextWriteGate ?? (command.isEmpty ? nextClearGate : null);
    nextWriteGate = null;
    if (gate != null && command.isEmpty) nextClearGate = null;
    final write = _writeTail.then((_) async {
      if (writeGap != Duration.zero) await Future<void>.delayed(writeGap);
      ledCommands.add(command);
      if (gate != null) await gate.future;
    });
    // A failed command does not prevent the next simulated native write.
    _writeTail = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    await write;
  }

  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) async {
    beepCommands.add([frequencyHz, durationMs]);
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

  test(
    'LED requests share pending writes and canonical square order',
    () async {
      final board = _FakeElectronicBoard();
      final leds = ChessnutLedController(board);
      final gate = Completer<void>();
      board.nextWriteGate = gate;
      final first = leds.setLeds(['e7', 'e5']);
      final duplicate = leds.setLeds([' E5 ', 'e7', 'e5']);
      final refresh = leds.setLeds(['e5', 'e7'], refresh: true);
      expect(identical(first, duplicate), isTrue);
      expect(identical(first, refresh), isTrue);
      gate.complete();
      await Future.wait([first, duplicate, refresh]);
      expect(board.ledCommands, [
        ['e5', 'e7'],
      ]);

      await leds.setLeds(['e7', 'e5']);
      expect(board.ledCommands, hasLength(1));
      await leds.setLeds(['e7', 'e5'], refresh: true);
      expect(board.ledCommands, hasLength(2));
      await leds.setLeds(['e5']);
      expect(board.ledCommands.last, ['e5']);
      await leds.setLeds([]);
      expect(board.ledCommands.last, isEmpty);
      await board.close();
    },
  );

  test('failed LED writes and reconnects permit an identical retry', () async {
    final board = _FakeElectronicBoard();
    final leds = ChessnutLedController(board);
    final gate = Completer<void>();
    board.nextWriteGate = gate;
    final failed = leds.setLeds(['e7', 'e5']);
    final failure = expectLater(failed, throwsA(isA<PlatformException>()));
    gate.completeError(PlatformException(code: 'write_failed'));
    await failure;
    await leds.setLeds(['e7', 'e5']);
    expect(board.ledCommands, hasLength(2));
    leds.invalidate();
    await leds.setLeds(['e7', 'e5']);
    expect(board.ledCommands, hasLength(3));
    await board.close();
  });

  test('an obsolete failure cannot invalidate a newer LED request', () async {
    final board = _FakeElectronicBoard();
    final leds = ChessnutLedController(board);
    final gate = Completer<void>();
    board.nextWriteGate = gate;
    final obsolete = leds.setLeds(['e7', 'e5']);
    final failure = expectLater(obsolete, throwsA(isA<PlatformException>()));
    leds.invalidate();
    final current = leds.setLeds(['d7', 'd5']);
    gate.completeError(PlatformException(code: 'connection_closed'));
    await failure;
    await current;
    await leds.setLeds(['d5', 'd7']);
    expect(board.ledCommands, [
      ['e5', 'e7'],
      ['d5', 'd7'],
    ]);
    await board.close();
  });

  testWidgets('delayed clear must not erase a newer pending Maia move', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final board = _FakeElectronicBoard();
    final pendingMaia = Completer<Float32List>();
    final policy = Float32List(4352)..fillRange(0, 4352, -100);
    policy[MaiaEncoding.moveIndex('e7e5', true)] = 100;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) => pendingMaia.future,
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

    final afterHuman = _after(chess.Chess(), 'e2e4');
    board.position(afterHuman);
    await tester.pump();
    expect(find.text('e4'), findsOneWidget);
    expect(find.text('e5'), findsNothing);

    // Reconnect while Maia thinks, invalidating the previous LED state.
    // A matching board notification starts a clear with delayed completion.
    await board.disconnect();
    board.writeGap = const Duration(milliseconds: 100);
    final clearGate = Completer<void>();
    board.nextClearGate = clearGate;
    board.ready(afterHuman);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(board.nextClearGate, isNull);

    // Maia returns before that old clear finishes. Non-empty writes are
    // serialized behind the active clear, as in the native bridge.
    pendingMaia.complete(policy);
    await tester.pump();
    expect(find.text('e5'), findsOneWidget);
    clearGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    final lastAfterRace = board.ledCommands.last.toSet();
    final countBeforeRefresh = board.ledCommands.length;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    final countAfterRefresh = board.ledCommands.length;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
    expect(
      lastAfterRace,
      containsAll(const ['e7', 'e5']),
      reason: 'The physical board still only has e4; Maia e5 must remain lit.',
    );
    expect(
      countAfterRefresh,
      greaterThan(countBeforeRefresh),
      reason: 'Pending Maia guidance must continue refreshing.',
    );
  });
  testWidgets('unchanged guidance must not be resent before refresh', (
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
    final afterHuman = _after(chess.Chess(), 'e2e4');
    board.position(afterHuman);
    await tester.pump();
    await tester.pump();
    int litCount() => board.ledCommands
        .where((c) => c.toSet().containsAll(['e7', 'e5']))
        .length;
    final initialCount = litCount();
    for (var i = 0; i < 5; i++) {
      board.position(afterHuman);
      await tester.pump(const Duration(milliseconds: 150));
    }
    final countAfterRepeatedPosition = litCount();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await board.close();
    expect(
      initialCount,
      1,
      reason: 'The first LED command already applied the same pending state.',
    );
    expect(
      countAfterRepeatedPosition,
      initialCount,
      reason: 'Unchanged physical positions must not bypass the two-second refresh cadence.',
    );
  });
}
