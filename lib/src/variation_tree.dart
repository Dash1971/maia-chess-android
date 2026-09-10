part of '../main.dart';

/// Combines equivalent saved continuations without changing the played line.
class VariationTree {
  static List<RecordedVariation> normalize(
    List<RecordedVariation> lines, {
    bool preserveFirst = false,
  }) {
    if (lines.isEmpty) return const [];
    final fens = <String, String>{};
    String positionKey(String fen) => fens.putIfAbsent(fen, () {
      try {
        return dc.Chess.fromSetup(dc.Setup.parseFen(fen)).fen;
      } on Exception {
        // Matching/export validation decides whether an orphan is usable.
        return fen;
      }
    });
    (int, String, String) key(RecordedVariation line) =>
        (line.basePly, positionKey(line.baseFen), line.sanMoves.join(' '));

    final mainlineKey = preserveFirst ? key(lines.first) : null;
    final indices = <(int, String, String), int>{};
    final result = <RecordedVariation>[];
    for (final original in lines) {
      final line = _normalizeLine(original, key(original) == mainlineKey);
      final lineKey = key(line);
      final existing = indices[lineKey];
      if (existing == null) {
        indices[lineKey] = result.length;
        result.add(line);
      } else {
        final previous = result[existing];
        result[existing] = RecordedVariation(
          basePly: previous.basePly,
          baseFen: previous.baseFen,
          sanMoves: previous.sanMoves,
          children: normalize([...previous.children, ...line.children]),
          annotations: [
            for (
              var i = 0;
              i < max(previous.annotations.length, line.annotations.length);
              i++
            )
              _mergeNote(_note(previous, i), _note(line, i)),
          ],
        );
      }
    }
    return List.unmodifiable(result);
  }

  static Map<String, dynamic> _note(RecordedVariation line, int index) =>
      index < line.annotations.length ? line.annotations[index] : const {};

  static Map<String, dynamic> _mergeNote(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) => {
    ...right,
    ...left,
    for (final key in ['comments', 'startingComments', 'nags'])
      if (left[key] is List || right[key] is List)
        key: <dynamic>{
          ...?left[key] as List?,
          ...?right[key] as List?,
        }.toList(),
  };

  static RecordedVariation _normalizeLine(
    RecordedVariation original,
    bool preserveMainline,
  ) {
    final children = normalize(original.children);
    final line = listEquals(children, original.children)
        ? original
        : RecordedVariation(
            basePly: original.basePly,
            baseFen: original.baseFen,
            sanMoves: original.sanMoves,
            children: children,
            annotations: original.annotations,
          );
    // A terminal child of the played line is an undone continuation, not a
    // played move. Keep that boundary even when the two representations merge.
    if (preserveMainline) return line;
    final endPly = line.basePly + line.sanMoves.length;
    if (!children.any(
      (child) => child.basePly == endPly && child.sanMoves.isNotEmpty,
    )) {
      return line;
    }
    try {
      final replay = chess.Chess.fromFEN(line.baseFen);
      for (final san in line.sanMoves) {
        if (!replay.move(san)) return line;
      }
      final extension = children
          .where(
            (child) =>
                child.basePly == endPly &&
                child.sanMoves.isNotEmpty &&
                PgnVariationExporter._samePosition(child.baseFen, replay.fen),
          )
          .firstOrNull;
      if (extension == null) return line;
      return RecordedVariation(
        basePly: line.basePly,
        baseFen: line.baseFen,
        sanMoves: [...line.sanMoves, ...extension.sanMoves],
        annotations: [
          for (var i = 0; i < line.sanMoves.length; i++) _note(line, i),
          ...extension.annotations,
        ],
        children: normalize([
          ...children.where((child) => !identical(child, extension)),
          ...extension.children,
        ]),
      );
    } on Exception {
      return line;
    }
  }
}
