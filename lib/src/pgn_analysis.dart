part of '../main.dart';

/// Portable annotations, not an engine cache: values are White's point of view.
class PgnAnalysisAnnotations {
  static final _eval = RegExp(
    r'\[%eval\s+(#[+-]?\d+|[+-]?(?:\d+(?:\.\d+)?|\.\d+))(?:\s*,\s*\d+)?\s*\]',
  );
  static const _quality = <int, MoveClassification>{
    1: MoveClassification.good,
    2: MoveClassification.mistake,
    3: MoveClassification.brilliant,
    4: MoveClassification.blunder,
    5: MoveClassification.interesting,
    6: MoveClassification.dubious,
  };

  static List<String> _withoutEval(List<String>? comments) => [
    for (final comment in comments ?? const <String>[])
      if (comment.replaceAll(_eval, '').trim().isNotEmpty)
        comment.replaceAll(_eval, '').trim(),
  ];

  static List<String> _withEval(
    List<String>? comments,
    StockfishReview score,
    String fen,
  ) {
    final checkmate = chess.Chess.fromFEN(fen).in_checkmate;
    final value = checkmate
        ? '#0'
        : score.mate != null
        ? '#${score.mate}'
        : (score.evaluation / 100).toStringAsFixed(2);
    return [..._withoutEval(comments), '[%eval $value]'];
  }

  static StockfishReview? _readEval(List<String>? comments, String fen) {
    final matches = _eval.allMatches((comments ?? const <String>[]).join(' '));
    if (matches.isEmpty) return null;
    final value = matches.last[1]!;
    if (value.startsWith('#')) {
      final mate = int.tryParse(value.substring(1));
      if (mate == null) return null;
      if (mate == 0) {
        final position = chess.Chess.fromFEN(fen);
        if (!position.in_checkmate) return null;
        return StockfishReview(
          0,
          '',
          mate: position.turn == chess.Color.WHITE ? -1 : 1,
        );
      }
      return StockfishReview(0, '', mate: mate);
    }
    final pawns = double.tryParse(value);
    if (pawns == null || !pawns.isFinite || pawns.abs() > 1000000) return null;
    return StockfishReview((pawns * 100).round(), '');
  }

  static String write(
    String pgn, {
    required List<StockfishReview> scores,
    required List<String> positions,
    required List<String> uciMoves,
    List<ClassifiedMove>? classifications,
  }) {
    final session = AnalysisSession.fromPgn(pgn);
    if (!listEquals(
          session.uciMoves.take(uciMoves.length).toList(),
          uciMoves,
        ) ||
        positions.length != uciMoves.length + 1 ||
        !PgnVariationExporter._samePosition(
          session.positions.first,
          positions.first,
        ) ||
        scores.length != positions.length) {
      throw const FormatException('Analysis does not match the PGN line.');
    }
    final parsed = dc.PgnGame.parsePgn(
      pgn,
      initHeaders: dc.PgnGame.emptyHeaders,
    );
    final marks = {
      for (final mark in classifications ?? const <ClassifiedMove>[])
        mark.ply: _quality.entries
            .firstWhere((entry) => entry.value == mark.classification)
            .key,
    };
    final tree = parsed.moves.transform<dc.PgnNodeData, (int, bool)>(
      (0, true),
      (context, data, index) {
        final (parentPly, main) = context;
        final ply = parentPly + 1;
        final onMainline = main && index == 0;
        return (
          (ply, onMainline),
          onMainline && ply < scores.length
              ? dc.PgnNodeData(
                  san: data.san,
                  comments: _withEval(
                    data.comments,
                    scores[ply],
                    positions[ply],
                  ),
                  startingComments: data.startingComments,
                  nags: classifications == null
                      ? data.nags
                      : [
                          for (final nag in data.nags ?? const <int>[])
                            if (!_quality.containsKey(nag)) nag,
                          if (marks[ply] != null) marks[ply]!,
                        ],
                )
              : data,
        );
      },
    );
    final output = dc.PgnGame(
      headers: parsed.headers,
      moves: tree,
      comments: _withEval(parsed.comments, scores.first, positions.first),
    ).makePgn().trim();
    if (utf8.encode(output).length > AnalysisSession.maxPgnBytes) {
      throw const FormatException('Annotated PGN exceeds 5 MB.');
    }
    return output;
  }

  static SavedPgnAnalysis read(String pgn, {List<String>? uciMoves}) {
    final session = AnalysisSession.fromPgn(pgn);
    final parsed = dc.PgnGame.parsePgn(
      pgn,
      initHeaders: dc.PgnGame.emptyHeaders,
    );
    final count = uciMoves?.length ?? session.uciMoves.length;
    if (uciMoves != null &&
        !listEquals(session.uciMoves.take(count).toList(), uciMoves)) {
      return const SavedPgnAnalysis(null, []);
    }
    final notes = [
      parsed.comments,
      for (final move in parsed.moves.mainline().take(count)) move.comments,
    ];
    final scores = [
      for (var i = 0; i < notes.length; i++)
        _readEval(notes[i], session.positions[i]),
    ];
    final marks = <ClassifiedMove>[];
    var ply = 0;
    for (final move in parsed.moves.mainline().take(count)) {
      ply++;
      final nag = move.nags?.reversed.where(_quality.containsKey).firstOrNull;
      if (nag != null) {
        marks.add(
          ClassifiedMove(
            ply: ply,
            classification: _quality[nag]!,
            moverIsWhite: session.positions[ply - 1].split(' ')[1] == 'w',
          ),
        );
      }
    }
    return SavedPgnAnalysis(
      scores.every((score) => score != null)
          ? scores.cast<StockfishReview>()
          : null,
      marks,
      // Game exports may omit the initial evaluation while annotating every
      // move. Preserve those scores so only the initial position needs work.
      // An explicit malformed initial annotation is not a missing annotation.
      moveScores:
          scores.length > 1 &&
              scores.first == null &&
              !(parsed.comments.join(' ').contains('[%eval')) &&
              scores.skip(1).every((score) => score != null)
          ? scores.skip(1).cast<StockfishReview>().toList(growable: false)
          : null,
    );
  }

  /// Strip evaluation comments and the six quality glyphs; keep prose, clocks,
  /// variations, headers and other positional NAGs. Storage is never changed.
  static String withoutAnalysis(String source) {
    final parsed = dc.PgnGame.parsePgn(
      source,
      initHeaders: dc.PgnGame.emptyHeaders,
    );
    final tree = parsed.moves.transform<dc.PgnNodeData, bool>(
      true,
      (_, data, _) => (
        true,
        dc.PgnNodeData(
          san: data.san,
          comments: _withoutEval(data.comments),
          startingComments: _withoutEval(data.startingComments),
          nags: [
            for (final nag in data.nags ?? const <int>[])
              if (!_quality.containsKey(nag)) nag,
          ],
        ),
      ),
    );
    return dc.PgnGame(
      headers: parsed.headers,
      moves: tree,
      comments: _withoutEval(parsed.comments),
    ).makePgn().trim();
  }
}

class SavedPgnAnalysis {
  const SavedPgnAnalysis(this.scores, this.classifications, {this.moveScores});
  final List<StockfishReview>? scores;
  final List<ClassifiedMove> classifications;

  /// All post-move scores, only when the initial evaluation alone is absent.
  final List<StockfishReview>? moveScores;
}

/// A working checkbox inside the existing Save/Share menu; toggling keeps the
/// menu open, so choosing an export action does not require a second dialog.
class PgnAnalysisExportOption<T> extends PopupMenuEntry<T> {
  const PgnAnalysisExportOption({
    required this.initialValue,
    required this.onChanged,
    super.key,
  });
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  @override
  double get height => kMinInteractiveDimension;
  @override
  bool represents(T? value) => false;
  @override
  State<PgnAnalysisExportOption<T>> createState() =>
      _PgnAnalysisExportOptionState<T>();
}

class _PgnAnalysisExportOptionState<T>
    extends State<PgnAnalysisExportOption<T>> {
  late bool _value = widget.initialValue;
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    key: const ValueKey('include-analysis-annotations'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(l10n(context).includeAnalysisAnnotations),
    value: _value,
    onChanged: (value) {
      if (value == null) return;
      setState(() => _value = value);
      widget.onChanged(value);
    },
  );
}
