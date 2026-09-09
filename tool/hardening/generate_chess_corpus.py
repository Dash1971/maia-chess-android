"""Generate a deterministic oracle corpus with python-chess (optional tooling)."""
import argparse
import json
import random
from pathlib import Path
import chess

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--positions', type=int, default=256)
parser.add_argument('--seed', type=int, default=20260909)
args = parser.parse_args()
rng = random.Random(args.seed)
# Castling, pinned en passant, promotions, checkmate, stalemate, fifty moves.
seeds = [chess.STARTING_FEN,
    'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
    '8/8/8/r4pPK/8/8/8/7k w - f6 0 1',
    '7k/P7/8/8/8/8/7p/K7 w - - 0 1',
    '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1',
    '7k/5K2/6Q1/8/8/8/8/8 b - - 0 1',
    '8/8/8/8/8/7k/R7/K7 w - - 99 1']
rows = []
board = chess.Board()
for i in range(args.positions):
    if i < len(seeds):
        board = chess.Board(seeds[i])
    elif board.is_game_over() or i % 120 == 0 or i == len(seeds):
        board = chess.Board()
    legal = sorted(board.legal_moves, key=lambda move: move.uci())
    selected = rng.choice(legal) if legal else None
    row = {'fen': board.fen(en_passant='fen'),
           'legal': [move.uci() for move in legal],
           'checkmate': board.is_checkmate(), 'stalemate': board.is_stalemate()}
    perspective = board if board.turn == chess.WHITE else board.mirror()
    row['tokenOnes'] = sorted(square * 12 + piece.piece_type - 1 +
                             (0 if piece.color == chess.WHITE else 6)
                             for square, piece in perspective.piece_map().items())
    if selected:
        row['move'] = selected.uci()
        row['san'] = board.san(selected)
        board.push(selected)
        row['after'] = board.fen(en_passant='fen')
    rows.append(row)
args.output.parent.mkdir(parents=True, exist_ok=True)
vocabulary = [chess.square_name(a) + chess.square_name(b)
              for a in chess.SQUARES for b in chess.SQUARES]
vocabulary += [f'{a}7{b}8{piece}' for a in 'abcdefgh'
               for b in 'abcdefgh' for piece in 'qrbn']
mirrored = [chess.square_name(chess.square_mirror(chess.parse_square(move[:2]))) +
            chess.square_name(chess.square_mirror(chess.parse_square(move[2:4]))) +
            move[4:] for move in vocabulary]
args.output.write_text(json.dumps({'generator': f'python-chess {chess.__version__}',
    'seed': args.seed, 'vocabulary': vocabulary, 'mirroredVocabulary': mirrored,
    'positions': rows}, separators=(',', ':'))+'\n')
print(f'Wrote {len(rows)} positions to {args.output}')
