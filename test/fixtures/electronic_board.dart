import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:maia_chess/main.dart';

/// A controllable transport; no Bluetooth adapter or physical board is used.
class SimulatedElectronicBoard implements ElectronicBoardTransport {
  final controller = StreamController<ElectronicBoardEvent>.broadcast(
    sync: true,
  );
  int connects = 0;
  int disconnects = 0;
  final leds = <List<String>>[];
  Completer<void>? connectGate;
  Completer<void>? disconnectGate;
  Completer<void>? writeGate;
  String connectFen = chess.Chess.DEFAULT_POSITION;

  @override
  Stream<ElectronicBoardEvent> get events => controller.stream;

  void status(ElectronicBoardConnectionState state) => controller.add(
    ElectronicBoardEvent(type: 'status', connectionState: state),
  );

  void position(String fen) => controller.add(
    ElectronicBoardEvent(
      type: 'position',
      position: ChessnutProtocol.pieceMapFromFen(fen),
    ),
  );

  @override
  Future<void> connect() async {
    connects++;
    if (connectGate case final gate?) await gate.future;
    status(ElectronicBoardConnectionState.ready);
    position(connectFen);
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
    if (disconnectGate case final gate?) await gate.future;
    status(ElectronicBoardConnectionState.disconnected);
  }

  @override
  Future<void> setLeds(Iterable<String> squares) async {
    leds.add(squares.toList());
    final gate = writeGate;
    writeGate = null;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) async {}

  Future<void> close() => controller.close();
}
