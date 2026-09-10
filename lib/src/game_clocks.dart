part of '../main.dart';

/// Unknown entries keep their ply rather than shifting later snapshots forward.
List<ClockSnapshot?> restoreClockHistory(Object? saved, int positions) {
  final entries = saved is List ? saved : const [];
  return List.generate(positions, (ply) {
    final entry = ply < entries.length ? entries[ply] : null;
    if (entry is! List || entry.length != 2) return null;
    final white = entry[0];
    final black = entry[1];
    if (white is! int || black is! int || white < 0 || black < 0) return null;
    return ClockSnapshot(white, black);
  });
}

class PgnClockExporter {
  static final RegExp _clockTag = RegExp(r'\s*\[%clk\s+[^\]]+\]');

  static String format(int milliseconds) {
    final value = max(0, milliseconds);
    final hours = value ~/ 3600000;
    final minutes = (value ~/ 60000 % 60).toString().padLeft(2, '0');
    final seconds = (value ~/ 1000 % 60).toString().padLeft(2, '0');
    final millis = (value % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  /// Clock tags belong only to the played main line. If a played move becomes
  /// a takeback variation, retain its human annotations but remove clock data.
  static Map<String, dynamic> withoutClockTags(
    Map<String, dynamic> annotation,
  ) {
    final result = Map<String, dynamic>.of(annotation);
    for (final key in const ['comments', 'startingComments']) {
      final values = (result[key] as List?)?.cast<String>();
      if (values == null) continue;
      final cleaned = values
          .map((text) => text.replaceAll(_clockTag, '').trim())
          .where((text) => text.isNotEmpty)
          .toList(growable: false);
      if (cleaned.isEmpty) {
        result.remove(key);
      } else {
        result[key] = cleaned;
      }
    }
    return result;
  }

  /// Annotate only played moves. Imported clock tags are authoritative.
  static String export(
    String pgn, {
    required List<ClockSnapshot?> history,
    int? baseSeconds,
    int incrementSeconds = 0,
  }) {
    if (baseSeconds == null) return pgn;
    final game = dc.PgnGame.parsePgn(pgn, initHeaders: dc.PgnGame.emptyHeaders);
    game.headers.putIfAbsent(
      'TimeControl',
      () => '$baseSeconds+$incrementSeconds',
    );
    var side = dc.Setup.parseFen(
      game.headers['FEN'] ?? chess.Chess.DEFAULT_POSITION,
    ).turn;
    var ply = 0;
    for (final move in game.moves.mainline()) {
      ply++;
      final snapshot = ply < history.length ? history[ply] : null;
      if (snapshot != null &&
          !(move.comments ?? const []).any((text) => text.contains('[%clk '))) {
        final millis = side == dc.Side.white
            ? snapshot.whiteMillis
            : snapshot.blackMillis;
        move.comments = [...?move.comments, '[%clk ${format(millis)}]'];
      }
      side = side.opposite;
    }
    return game.makePgn().trim();
  }
}
