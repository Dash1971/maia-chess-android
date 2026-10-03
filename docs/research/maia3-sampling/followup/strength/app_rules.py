"""Exact app-outcome helper reused from the prior validated draw sensitivity."""
import chess


def key(board):
    return ' '.join(board.fen(en_passant='fen').split(' ')[:4])


def app_outcome(board, counts):
    if board.is_checkmate():
        return ('0-1' if board.turn == chess.WHITE else '1-0', 'checkmate')
    if board.halfmove_clock >= 100:
        return ('1/2-1/2', 'fifty_moves_actual')
    if board.is_stalemate():
        return ('1/2-1/2', 'stalemate')
    if board.is_insufficient_material():
        return ('1/2-1/2', 'insufficient_material')
    if max(counts.values()) >= 3:
        return ('1/2-1/2', 'threefold_repetition_actual')
    return None
