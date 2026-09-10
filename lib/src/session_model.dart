part of '../main.dart';

class PgnVariationExporter {
  static const _unplayedPrefix = 'Unplayed takeback line';

  static bool _samePosition(String left, String right) {
    if (left == right) return true;
    try {
      // Older analysis records omit an en-passant target when no capture is
      // legal. Canonicalize that notation without ignoring real capture rights.
      return dc.Chess.fromSetup(dc.Setup.parseFen(left)).fen ==
          dc.Chess.fromSetup(dc.Setup.parseFen(right)).fen;
    } on Exception {
      return false;
    }
  }

  static List<RecordedVariation> annotationsForMainline(
    List<String> mainSan,
    List<RecordedVariation> reviewTree,
  ) {
    final rootIndex = reviewTree.indexWhere(
      (line) =>
          line.basePly == 0 &&
          line.sanMoves.length == mainSan.length &&
          List.generate(
            mainSan.length,
            (index) => line.sanMoves[index] == mainSan[index],
          ).every((matches) => matches),
    );
    if (rootIndex < 0) return List.unmodifiable(reviewTree);
    final root = reviewTree[rootIndex];
    return List.unmodifiable([
      ...root.children,
      for (var index = 0; index < reviewTree.length; index++)
        if (index != rootIndex) reviewTree[index],
    ]);
  }

  static List<RecordedVariation> parseTree(String pgn) {
    final parsed = dc.PgnGame.parsePgn(
      pgn,
      initHeaders: dc.PgnGame.emptyHeaders,
    );
    final fen = parsed.headers['FEN'] ?? chess.Chess.DEFAULT_POSITION;
    AnalysisSession.validateFen(fen);
    var nodes = 0;
    RecordedVariation line(
      dc.PgnChildNode<dc.PgnNodeData> first,
      String baseFen,
      int basePly,
      int depth,
    ) {
      if (depth > 64) {
        throw const FormatException('PGN variations are too deeply nested.');
      }
      final game = chess.Chess.fromFEN(baseFen);
      final san = <String>[];
      final annotations = <Map<String, dynamic>>[];
      final children = <RecordedVariation>[];
      var node = first;
      while (true) {
        if (++nodes > 20000) {
          throw const FormatException('PGN has too many moves.');
        }
        if (!game.move(node.data.san)) {
          throw FormatException('Illegal PGN move: ${node.data.san}');
        }
        san.add(node.data.san);
        annotations.add({
          if (node.data.comments != null) 'comments': node.data.comments,
          if (node.data.startingComments != null)
            'startingComments': node.data.startingComments,
          if (node.data.nags != null) 'nags': node.data.nags,
        });
        for (final sibling in node.children.skip(1)) {
          children.add(
            line(sibling, game.fen, basePly + san.length, depth + 1),
          );
        }
        if (node.children.isEmpty) break;
        node = node.children.first;
      }
      return RecordedVariation(
        basePly: basePly,
        baseFen: baseFen,
        sanMoves: List.unmodifiable(san),
        children: children,
        annotations: annotations,
      );
    }

    return VariationTree.normalize(
      parsed.moves.children.map((node) => line(node, fen, 0, 0)).toList(),
      preserveFirst: true,
    );
  }

  static String export(
    String pgn,
    List<String> mainSan,
    List<RecordedVariation> variations, {
    List<String>? mainPositions,
    List<Map<String, dynamic>>? mainAnnotations,
    List<String>? startingComments,
    bool preserveEmptyMainline = false,
  }) {
    final source = dc.PgnGame.parsePgn(
      pgn,
      initHeaders: dc.PgnGame.emptyHeaders,
    );
    final headers = Map<String, String>.of(source.headers);
    headers.putIfAbsent('Result', () => '*');
    final roots = <RecordedVariation>[];
    final unplayed = <RecordedVariation>[];
    if (mainSan.isNotEmpty) {
      final seed = source.moves.mainline().toList();
      bool matchesMainline(RecordedVariation line) =>
          mainPositions == null ||
          (line.basePly < mainPositions.length &&
              _samePosition(line.baseFen, mainPositions[line.basePly]));
      unplayed.addAll(
        variations.where(
          (line) => line.basePly == mainSan.length && matchesMainline(line),
        ),
      );
      roots.add(
        RecordedVariation(
          basePly: 0,
          baseFen:
              mainPositions?.first ??
              headers['FEN'] ??
              chess.Chess.DEFAULT_POSITION,
          sanMoves: mainSan,
          annotations:
              mainAnnotations ??
              [
                for (final data in seed)
                  {
                    if (data.comments != null) 'comments': data.comments,
                    if (data.startingComments != null)
                      'startingComments': data.startingComments,
                    if (data.nags != null) 'nags': data.nags,
                  },
              ],
          children: variations
              .where(
                (v) =>
                    v.basePly > 0 &&
                    v.basePly < mainSan.length &&
                    matchesMainline(v),
              )
              .toList(),
        ),
      );
      roots.addAll(variations.where((v) => v.basePly == 0));
    } else {
      roots.addAll(variations.where((v) => v.basePly == 0));
      if (roots.isNotEmpty) {
        final first = roots.first;
        roots[0] = RecordedVariation(
          basePly: 0,
          baseFen: first.baseFen,
          sanMoves: first.sanMoves,
          annotations: first.annotations,
          children: [
            ...first.children,
            ...variations.where((v) => v.basePly > 0),
          ],
        );
      }
    }
    final rootFen = roots.firstOrNull?.baseFen ?? headers['FEN'];
    if (rootFen != null && rootFen != chess.Chess.DEFAULT_POSITION) {
      headers['SetUp'] = '1';
      headers['FEN'] = rootFen;
    }
    final tree = dc.PgnNode<dc.PgnNodeData>();
    void addLine(dc.PgnNode<dc.PgnNodeData> parent, RecordedVariation line) {
      var node = parent;
      final parents = <dc.PgnNode<dc.PgnNodeData>>[parent];
      for (var index = 0; index < line.sanMoves.length; index++) {
        final note = index < line.annotations.length
            ? line.annotations[index]
            : const <String, dynamic>{};
        final child = dc.PgnChildNode(
          dc.PgnNodeData(
            san: line.sanMoves[index],
            comments: (note['comments'] as List?)?.cast<String>(),
            startingComments: (note['startingComments'] as List?)
                ?.cast<String>(),
            nags: (note['nags'] as List?)?.cast<int>(),
          ),
        );
        node.children.add(child);
        node = child;
        parents.add(child);
      }
      for (final child in line.children) {
        final offset = child.basePly - line.basePly;
        if (offset >= 0 && offset < parents.length) {
          addLine(parents[offset], child);
        }
      }
    }

    for (final root in VariationTree.normalize(roots, preserveFirst: true)) {
      addLine(tree, root);
    }
    final comments = [
      for (final comment in startingComments ?? source.comments)
        if (!preserveEmptyMainline || !comment.startsWith(_unplayedPrefix))
          comment,
    ];
    if (preserveEmptyMainline &&
        ((mainSan.isEmpty && roots.isNotEmpty) || unplayed.isNotEmpty)) {
      // A RAV needs a played sibling move. Until a replacement move exists,
      // keep an abandoned terminal continuation readable without promoting it
      // back into the played main line. Session JSON retains the editable tree.
      final noteTree = mainSan.isEmpty ? tree : dc.PgnNode<dc.PgnNodeData>();
      if (mainSan.isNotEmpty) {
        for (final line in VariationTree.normalize(unplayed)) {
          addLine(noteTree, line);
        }
      }
      final noteFen = mainSan.isEmpty ? rootFen : unplayed.first.baseFen;
      final noteHeaders = <String, String>{'Result': '*'};
      if (noteFen != null && noteFen != chess.Chess.DEFAULT_POSITION) {
        noteHeaders.addAll({'SetUp': '1', 'FEN': noteFen});
      }
      final rendered =
          dc.PgnGame(headers: noteHeaders, moves: noteTree, comments: const [])
              .makePgn()
              .replaceAll(RegExp(r'^\[.*\]\s*', multiLine: true), '')
              .replaceAll('{', '(')
              .replaceAll('}', ')')
              .trim();
      final label = mainSan.isEmpty
          ? _unplayedPrefix
          : '$_unplayedPrefix after ply ${mainSan.length}';
      comments.add('$label: $rendered');
      if (mainSan.isEmpty) {
        return dc.PgnGame(
          headers: headers,
          moves: dc.PgnNode<dc.PgnNodeData>(),
          comments: comments,
        ).makePgn().trim();
      }
    }
    return dc.PgnGame(
      headers: headers,
      moves: tree,
      comments: comments,
    ).makePgn().trim();
  }
}

class AnalysisSession {
  const AnalysisSession({
    required this.positions,
    required this.uciMoves,
    required this.sanMoves,
    required this.pgn,
  });

  final List<String> positions;
  final List<String> uciMoves;
  final List<String> sanMoves;
  final String pgn;

  Map<String, Object> toJson() => {
    'positions': positions,
    'uciMoves': uciMoves,
    'sanMoves': sanMoves,
    'pgn': pgn,
  };

  factory AnalysisSession.fromJson(Map<String, dynamic> json) =>
      AnalysisSession.fromPgn(json['pgn'] as String);

  // Keep the isolate closure out of widget methods: another closure in the
  // same method can make it capture an unsendable State/BuildContext as well.
  static Future<AnalysisSession> fromPgnAsync(String source) =>
      Isolate.run(() => AnalysisSession.fromPgn(source));

  static void validateFen(String fen) {
    try {
      dc.Chess.fromSetup(dc.Setup.parseFen(fen.trim()));
      final result = chess.Chess.validate_fen(fen.trim());
      if (result['valid'] != true) {
        throw FormatException(result['error'].toString());
      }
    } catch (error) {
      throw FormatException('Invalid chess position: $error');
    }
  }

  static void _validatePgnTokens(String source) {
    var movetext = source.replaceFirst('\ufeff', '');
    movetext = movetext.replaceAll(
      RegExp(r'\[[A-Za-z0-9][A-Za-z0-9_+#=:-]*\s+"(?:[^"\\]|\\["\\])*"\]'),
      ' ',
    );
    movetext = movetext.replaceAll(RegExp(r'^\s*%.*$', multiLine: true), ' ');

    final uncommented = StringBuffer();
    var inBraceComment = false;
    var inLineComment = false;
    for (final codeUnit in movetext.codeUnits) {
      final character = String.fromCharCode(codeUnit);
      if (inBraceComment) {
        if (character == '}') inBraceComment = false;
        continue;
      }
      if (inLineComment) {
        if (character == '\n' || character == '\r') {
          inLineComment = false;
          uncommented.write(' ');
        }
        continue;
      }
      if (character == '{') {
        inBraceComment = true;
      } else if (character == ';') {
        inLineComment = true;
      } else if (character == '}') {
        throw const FormatException('Malformed PGN comment.');
      } else {
        uncommented.write(character);
      }
    }
    if (inBraceComment) {
      throw const FormatException('Malformed PGN comment.');
    }

    movetext = uncommented.toString();
    var variationDepth = 0;
    for (final character in movetext.codeUnits) {
      if (character == 0x28 && ++variationDepth > 64) {
        throw const FormatException('PGN variations are too deeply nested.');
      }
      if (character == 0x29 && --variationDepth < 0) {
        throw const FormatException('Malformed PGN variation.');
      }
    }
    if (variationDepth != 0) {
      throw const FormatException('Malformed PGN variation.');
    }

    movetext = movetext.replaceAll(RegExp(r'\d+\.(?:\.\.)?'), ' ');
    movetext = movetext.replaceAll(
      RegExp(
        r'(?:[NBKRQ]?[a-h]?[1-8]?[-x]?[a-h][1-8](?:=?[nbrqkNBRQK])?|[pnbrqkPNBRQK]?@[a-h][1-8]|O-O-O|0-0-0|O-O|0-0)[+#]?|--|Z0|0000|@@@@|\$\d{1,4}|[?!]{1,2}|\(|\)|\*|1-0|0-1|1/2-1/2',
      ),
      ' ',
    );
    if (movetext.trim().isNotEmpty) {
      throw const FormatException('The PGN contains invalid movetext.');
    }
  }

  factory AnalysisSession.fromFen(String fen) {
    validateFen(fen);
    final game = chess.Chess.fromFEN(fen.trim());
    game.set_header([
      'Event',
      'Mobile Maia Analysis',
      'SetUp',
      '1',
      'FEN',
      fen.trim(),
      'Result',
      '*',
    ]);
    return AnalysisSession(
      positions: [game.fen],
      uciMoves: const [],
      sanMoves: const [],
      pgn: game.pgn(),
    );
  }

  factory AnalysisSession.start() =>
      AnalysisSession.fromFen(chess.Chess.DEFAULT_POSITION);

  factory AnalysisSession.fromPgn(String source) {
    if (source.length > 2 * 1024 * 1024 ||
        utf8.encode(source).length > 2 * 1024 * 1024) {
      throw const FormatException('PGN is too large.');
    }
    _validatePgnTokens(source);
    final parsed = dc.PgnGame.parsePgn(
      source.trim(),
      initHeaders: dc.PgnGame.emptyHeaders,
    );
    final baseFen = parsed.headers['FEN'] ?? chess.Chess.DEFAULT_POSITION;
    validateFen(baseFen);
    // Validate every branch, not just the displayed mainline.
    final roots = PgnVariationExporter.parseTree(source);
    if (roots.isEmpty && parsed.headers.isEmpty && source.trim() != '*') {
      throw const FormatException('The PGN contains no game.');
    }
    final replay = chess.Chess.fromFEN(baseFen);
    final positions = <String>[replay.fen];
    final uciMoves = <String>[];
    final sanMoves = roots.firstOrNull?.sanMoves ?? const <String>[];
    for (final san in sanMoves) {
      if (!replay.move(san)) throw FormatException('Illegal PGN move: $san');
      uciMoves.add(MaiaEncoding.uci(replay.history.last.move));
      positions.add(replay.fen);
    }
    return AnalysisSession(
      positions: List.unmodifiable(positions),
      uciMoves: List.unmodifiable(uciMoves),
      sanMoves: List.unmodifiable(sanMoves),
      pgn: parsed.makePgn().trim(),
    );
  }
}
