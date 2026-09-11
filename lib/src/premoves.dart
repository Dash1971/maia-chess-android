part of '../main.dart';

/// A visual plan, never a legal chess position or a source of committed moves.
/// Every move is checked again against the real game when its turn arrives.
class PremoveSequence {
  static const maximumLength = 64;
  final List<dc.NormalMove> _moves = [];
  List<dc.NormalMove> get moves => List.unmodifiable(_moves);
  bool get isEmpty => _moves.isEmpty;
  int get length => _moves.length;
  void clear() => _moves.clear();
  dc.NormalMove? takeNext() => _moves.isEmpty ? null : _moves.removeAt(0);

  bool add(String fen, dc.Side side, dc.NormalMove move) {
    if (_moves.length >= maximumLength) return false;
    final pieces = cg.readFen(project(fen, side));
    final piece = pieces[move.from];
    if (piece?.color != side ||
        !cg.premovesOf(move.from, pieces, canCastle: true).contains(move.to)) {
      return false;
    }
    move = normalize(piece!, move);
    _moves.add(move);
    return true;
  }

  static dc.NormalMove normalize(dc.Piece piece, dc.NormalMove move) {
    // Chessground also accepts king-to-rook castling gestures. The game uses
    // standard UCI, so retain one representation for validation and projection.
    if (piece.role == dc.Role.king &&
        move.from.file == 4 &&
        move.from.rank == move.to.rank &&
        (move.to.file == 0 || move.to.file == 7)) {
      move = dc.NormalMove(
        from: move.from,
        to: dc.Square.fromCoords(
          move.to.file == 0 ? dc.File.c : dc.File.g,
          move.from.rank,
        ),
      );
    }
    if (piece.role == dc.Role.pawn &&
        (move.to.rank == 0 || move.to.rank == 7)) {
      move = dc.NormalMove(
        from: move.from,
        to: move.to,
        promotion: move.promotion ?? dc.Role.queen,
      );
    }
    return move;
  }

  String project(String fen, dc.Side side) {
    var board = dc.Setup.parseFen(fen).board;
    for (final move in _moves) {
      final piece = board.pieceAt(move.from);
      if (piece == null || piece.color != side) continue;
      if (piece.role == dc.Role.king &&
          move.from.file == 4 &&
          move.from.rank == move.to.rank &&
          (move.to.file == 2 || move.to.file == 6)) {
        final rookFrom = dc.Square.fromCoords(
          move.to.file == 2 ? dc.File.a : dc.File.h,
          move.from.rank,
        );
        final rookTo = dc.Square.fromCoords(
          move.to.file == 2 ? dc.File.d : dc.File.f,
          move.from.rank,
        );
        final rook = board.pieceAt(rookFrom);
        if (rook?.role == dc.Role.rook && rook?.color == side) {
          board = board.removePieceAt(rookFrom).setPieceAt(rookTo, rook!);
        }
      }
      if (piece.role == dc.Role.pawn &&
          move.from.file != move.to.file &&
          board.pieceAt(move.to) == null) {
        final captured = dc.Square.fromCoords(move.to.file, move.from.rank);
        if (board.pieceAt(captured) ==
            dc.Piece(color: side.opposite, role: dc.Role.pawn)) {
          board = board.removePieceAt(captured);
        }
      }
      board = board
          .removePieceAt(move.from)
          .setPieceAt(
            move.to,
            dc.Piece(color: side, role: move.promotion ?? piece.role),
          );
    }
    // No legality assumptions: opponent replies have not happened yet.
    return '${board.fen} ${side.opposite == dc.Side.white ? 'w' : 'b'} - - 0 1';
  }

  /// One tint per square: the last queued use wins, without stacking opacity.
  Map<dc.Square, bool> get destinations {
    final result = <dc.Square, bool>{};
    for (final move in _moves) {
      result[move.from] = false;
      result[move.to] = true;
    }
    return result;
  }
}

class PremoveHighlights extends CustomPainter {
  PremoveHighlights(this.squares, this.orientation, this.color);
  final Map<dc.Square, bool> squares;
  final dc.Side orientation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    for (final entry in squares.entries) {
      final white = orientation == dc.Side.white;
      final x = white ? entry.key.file : 7 - entry.key.file;
      final y = white ? 7 - entry.key.rank : entry.key.rank;
      canvas.drawRect(
        Rect.fromLTWH(x * squareSize, y * squareSize, squareSize, squareSize),
        Paint()..color = color.withValues(alpha: entry.value ? 0.28 : 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(PremoveHighlights oldDelegate) =>
      oldDelegate.orientation != orientation ||
      oldDelegate.color != color ||
      !mapEquals(oldDelegate.squares, squares);
}
