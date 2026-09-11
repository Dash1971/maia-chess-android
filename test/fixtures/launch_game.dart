import 'dart:async';
import 'dart:typed_data';

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

class TestClock extends Stopwatch {
  TestClock(this.milliseconds);
  int milliseconds;
  @override
  int get elapsedMilliseconds => milliseconds;
}

class ControlledMaia {
  final requests = <(String, Completer<Float32List>)>[];
  Future<Float32List> call(List<String> positions, int elo) {
    final reply = Completer<Float32List>();
    requests.add((positions.last, reply));
    return reply.future;
  }

  void reply(String uci) {
    final (fen, pending) = requests.last;
    final policy = Float32List(4352)..fillRange(0, 4352, -100);
    policy[MaiaEncoding.moveIndex(uci, fen.split(' ')[1] == 'b')] = 100;
    pending.complete(policy);
  }
}

cg.Chessboard boardOf(WidgetTester tester) =>
    tester.widget<cg.Chessboard>(find.byKey(const ValueKey('game-board')));
Future<void> flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> disposeGame(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Offset squareCenter(WidgetTester tester, String name) {
  final board = boardOf(tester);
  final box = tester.getRect(find.byKey(const ValueKey('game-board')));
  final square = dc.Square.fromName(name);
  final white = board.orientation == dc.Side.white;
  final x = white ? square.file : 7 - square.file;
  final y = white ? 7 - square.rank : square.rank;
  return box.topLeft +
      Offset((x + .5) * box.width / 8, (y + .5) * box.width / 8);
}

Future<void> tapSquare(WidgetTester tester, String name) async {
  await tester.tapAt(squareCenter(tester, name));
  await flush(tester);
}

Future<void> queueMove(WidgetTester tester, String uci) async {
  await tapSquare(tester, uci.substring(0, 2));
  await tapSquare(tester, uci.substring(2, 4));
}

Map<String, Object?> gameRecord({
  String? pgn,
  String preset = 'blitz',
  int white = 5000,
  int black = 5000,
  bool playerWhite = true,
  List<Object?>? history,
  String? result,
}) => {
  'type': 'game',
  'pgn': pgn ?? AnalysisSession.start().pgn,
  'timePreset': preset,
  'whiteMillis': white,
  'blackMillis': black,
  'playerIsWhite': playerWhite,
  'clockPaused': true,
  'clockHistory': ?history,
  'forcedResult': ?result,
};
