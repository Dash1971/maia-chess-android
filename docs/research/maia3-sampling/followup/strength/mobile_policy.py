"""Mobile Maia stable25 policy: repeat current board, vertical black mirror, legal-only nucleus."""
import hashlib, math, random, os
from pathlib import Path
import chess
import numpy as np
import onnxruntime as ort

ROOT = Path(__file__).resolve().parent
MODEL79 = Path(os.environ.get('MAIA79_MODEL', str(ROOT / 'models/maia3-79m.onnx')))
MODEL5 = Path(os.environ.get('MAIA5_MODEL', str(ROOT / 'models/maia3-5m.onnx')))
MODEL_HASHES = {'3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010', 'ddae2aa893b5ca7ec94d24178871f1c337d09fd72ff38abe8d76b8ecf08cb942'}

def encode(board):
    current = np.zeros((64, 12), dtype=np.float32)
    black = board.turn == chess.BLACK
    for square, piece in board.piece_map().items():
        sq = chess.square_mirror(square) if black else square
        white = (piece.color == chess.WHITE) != black
        current[sq, piece.piece_type-1 + (0 if white else 6)] = 1
    tokens = np.zeros((64,97),dtype=np.float32)
    for h in range(8): tokens[:,h*12:(h+1)*12] = current
    return tokens

def move_index(move, black=False):
    f,t = move.from_square,move.to_square
    if black: f,t = chess.square_mirror(f),chess.square_mirror(t)
    if move.promotion:
        return 4096 + (chess.square_file(f)*8+chess.square_file(t))*4 + {chess.QUEEN:0,chess.ROOK:1,chess.BISHOP:2,chess.KNIGHT:3}[move.promotion]
    return f*64+t

def distribution(board, logits, top_p=1., temperature=1.):
    moves=list(board.legal_moves)
    values=np.array([float(logits[move_index(m,board.turn==chess.BLACK)]) for m in moves],dtype=np.float64)
    if temperature<=0:
        return [moves[int(np.argmax(values))]],np.ones(1)
    values/=min(1.,max(.001,temperature))
    weights=np.exp(values-values.max())
    order=np.argsort(-weights,kind='stable')
    moves=[moves[i] for i in order];weights=weights[order]
    p=min(1.,max(0.,top_p))
    if p<1:
        count=int(np.searchsorted(np.cumsum(weights/weights.sum()),p,side='left'))+1
        moves=moves[:count];weights=weights[:count]
    return moves,weights/weights.sum()

def sample(board, logits, top_p=1., temperature=1., rng=None):
    moves,probs=distribution(board,logits,top_p,temperature)
    if len(moves)==1:return moves[0]
    target=(rng or random).random()
    for move,p in zip(moves,probs):
        target-=p
        if target<=0:return move
    return moves[-1]

class Policy:
    def __init__(self, model=MODEL79, threads=1, cache_limit=100000):
        self.model=Path(model)
        if not self.model.is_file():raise FileNotFoundError(f'Model missing: {self.model}. Set MAIA79_MODEL / MAIA5_MODEL to the pinned ONNX files.')
        if sha256(self.model) not in MODEL_HASHES:raise ValueError('Model SHA-256 differs from pinned study exports')
        self.cache={};self.cache_limit=cache_limit;self.calls=0;self.hits=0
        options=ort.SessionOptions(); options.intra_op_num_threads=threads;options.inter_op_num_threads=1
        options.execution_mode=ort.ExecutionMode.ORT_SEQUENTIAL
        self.session=ort.InferenceSession(str(model),sess_options=options,providers=['CPUExecutionProvider'])
    def logits(self,board,self_elo=1600,opponent_elo=1600):
        # Encoder intentionally excludes rights, clocks, ep and real history; preserve those in chess board.
        key=(board.board_fen(),board.turn,self_elo,opponent_elo)
        if key in self.cache:self.hits+=1;return self.cache[key]
        value=self.session.run(['move_logits'],{'tokens':encode(board)[None,:,:],'self_elo':np.array([self_elo],np.int64),'opponent_elo':np.array([opponent_elo],np.int64)})[0][0]
        self.calls+=1
        if len(self.cache)<self.cache_limit:self.cache[key]=value
        return value
    def move(self,board,top_p,temperature,rng,self_elo=1600,opponent_elo=1600):
        return sample(board,self.logits(board,self_elo,opponent_elo),top_p,temperature,rng)

def sha256(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()
