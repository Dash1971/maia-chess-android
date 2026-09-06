part of '../main.dart';

class OpeningNames {
  static final Map<String, ({String eco, String name})> _byEpd = {};

  static Future<void> load() async {
    if (_byEpd.isNotEmpty) return;
    final source = await rootBundle.loadString(
      'assets/openings/lichess_openings.tsv',
    );
    for (final line in const LineSplitter().convert(source).skip(1)) {
      final columns = line.split('\t');
      if (columns.length != 5) continue;
      _byEpd[columns[4]] = (eco: columns[0], name: columns[1]);
    }
  }

  static String? identifyPositions(Iterable<String> positions) {
    for (final fen in positions.toList(growable: false).reversed) {
      final fields = fen.split(RegExp(r'\s+'));
      if (fields.length < 4) continue;
      final opening = _byEpd[fields.take(4).join(' ')];
      if (opening != null) return '${opening.eco} · ${opening.name}';
    }
    return null;
  }

  static String? identify(List<String> moves) {
    final game = chess.Chess();
    final positions = <String>[game.fen];
    for (final uci in moves) {
      final candidate = game
          .moves({'asObjects': true})
          .cast<chess.Move>()
          .where((move) => MaiaEncoding.uci(move) == uci)
          .firstOrNull;
      if (candidate == null || !game.move(candidate)) break;
      positions.add(game.fen);
    }
    return identifyPositions(positions);
  }
}
