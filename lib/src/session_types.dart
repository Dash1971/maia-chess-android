part of '../main.dart';

enum PlayerSide { white, black, random }

enum TimePreset {
  unlimited,
  bullet,
  blitz,
  blitzFive,
  rapid,
  classical,
  custom,
}

extension TimePresetDetails on TimePreset {
  String get label => switch (this) {
    TimePreset.unlimited => 'Unlimited',
    TimePreset.bullet => '1 + 0',
    TimePreset.blitz => '3 + 2',
    TimePreset.blitzFive => '5 + 3',
    TimePreset.rapid => '10 + 0',
    TimePreset.classical => '15 + 10',
    TimePreset.custom => 'Custom',
  };

  int get minutes => switch (this) {
    TimePreset.bullet => 1,
    TimePreset.blitz => 3,
    TimePreset.blitzFive => 5,
    TimePreset.rapid => 10,
    TimePreset.classical => 15,
    _ => 0,
  };

  int get increment => switch (this) {
    TimePreset.blitz => 2,
    TimePreset.blitzFive => 3,
    TimePreset.classical => 10,
    _ => 0,
  };
}

const maiaDrawEndgamePhaseLimit = 8;
const maiaDrawAcceptanceCentipawns = 30;

/// Returns the objective result of a naturally completed chess position.
///
/// This deliberately derives the result from the board instead of trusting a
/// PGN header, which can be stale in an interrupted or legacy saved session.
String? naturalGameResult(chess.Chess game) {
  if (!game.game_over) return null;
  if (game.in_checkmate) {
    return game.turn == chess.Color.WHITE ? '0-1' : '1-0';
  }
  return '1/2-1/2';
}

/// The side to move has flagged. An opponent without possible mating material
/// cannot win on time (FIDE 6.9). Use the chess library's side-specific test;
/// a lone minor piece can still mate with help from the opponent's material.
String timeoutGameResult(chess.Chess game) {
  final position = dc.Chess.fromSetup(dc.Setup.parseFen(game.fen));
  if (position.hasInsufficientMaterial(position.turn.opposite)) {
    return '1/2-1/2';
  }
  return game.turn == chess.Color.WHITE ? '0-1' : '1-0';
}

/// A deterministic material-phase measure for draw offers.
///
/// Queens count 4, rooks 2, and bishops/knights 1 across both sides.
/// Kings and pawns do not contribute. The initial position has phase 24.
int maiaMaterialPhase(String fen) {
  final board = fen.split(RegExp(r'\s+')).first;
  var phase = 0;
  for (final piece in board.codeUnits) {
    phase += switch (piece) {
      81 || 113 => 4, // Q/q
      82 || 114 => 2, // R/r
      66 || 98 || 78 || 110 => 1, // B/b/N/n
      _ => 0,
    };
  }
  return phase;
}

bool isMaiaDrawOfferEndgame(String fen) =>
    maiaMaterialPhase(fen) <= maiaDrawEndgamePhaseLimit;

bool shouldMaiaAcceptDraw({
  required String fen,
  required bool maiaIsWhite,
  required int whiteEvaluation,
  int? whiteMate,
}) {
  if (!isMaiaDrawOfferEndgame(fen)) return false;
  if (whiteMate != null) {
    final maiaMate = maiaIsWhite ? whiteMate : -whiteMate;
    return maiaMate < 0;
  }
  final maiaEvaluation = maiaIsWhite ? whiteEvaluation : -whiteEvaluation;
  return maiaEvaluation <= maiaDrawAcceptanceCentipawns;
}

class ClockSnapshot {
  const ClockSnapshot(this.whiteMillis, this.blackMillis);

  final int whiteMillis;
  final int blackMillis;
}

class RecordedVariation {
  const RecordedVariation({
    required this.basePly,
    required this.baseFen,
    required this.sanMoves,
    this.children = const [],
    this.annotations = const [],
  });

  final int basePly;
  final String baseFen;
  final List<String> sanMoves;
  final List<RecordedVariation> children;
  final List<Map<String, dynamic>> annotations;

  Map<String, Object> toJson() => {
    'basePly': basePly,
    'baseFen': baseFen,
    'sanMoves': sanMoves,
    'children': children.map((item) => item.toJson()).toList(),
    'annotations': annotations,
  };

  factory RecordedVariation.fromJson(Map<String, dynamic> json) =>
      RecordedVariation(
        annotations: (json['annotations'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        basePly: json['basePly'] as int,
        baseFen: json['baseFen'] as String,
        sanMoves: (json['sanMoves'] as List).cast<String>(),
        children: (json['children'] as List? ?? const [])
            .map(
              (item) => RecordedVariation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );
}
