import sys,json,hashlib,time,os
from pathlib import Path
from collections import deque
import chess,torch,numpy as np
root=Path(__file__).resolve().parent
sys.path.insert(0,os.environ['MAIA_SOURCE'])
from maia3.dataset import tokenize_board,get_historical_tokens
from maia3.uci import parse_args,load_model
from maia3.utils import get_all_possible_moves,mirror_move
torch.set_num_threads(1)
checkpoint=Path(os.environ['MAIA_CHECKPOINT'])
assert hashlib.sha256(checkpoint.read_bytes()).hexdigest()=='3fc6181d5db789b45a15305732148757ae74efa3e0028e81ba335b462dac45c2'
cfg=parse_args(['--model','maia3-79m','--checkpoint-path',str(checkpoint),'--device','cpu'])
model=load_model(cfg);cases=[]
source=[json.loads(l) for l in (root/'source/allie-test.jsonl').open()][:3]
for gi,g in enumerate(source):
 b=chess.Board();hist=[b.fen()]
 for ply in range(1,32):
  if ply>len(g['moves-uci'].split()):break
  b.push_uci(g['moves-uci'].split()[ply-1]);hist.append(b.fen())
  if ply in [1,2,7,8,21,30]:cases.append({'id':f'g{gi}p{ply}','history':hist[-8:].copy(),'self_elo':g['black-elo'] if b.turn==chess.BLACK else g['white-elo'],'opponent_elo':g['white-elo'] if b.turn==chess.BLACK else g['black-elo']})
cases.append({'id':'black-promotion','history':['7k/8/8/8/8/8/1p6/7K b - - 0 1'],'self_elo':1200,'opponent_elo':1800})
ix={m:i for i,m in enumerate(get_all_possible_moves())};tokens=[];records=[];outputs=[]
for c in cases:
 b=chess.Board(c['history'][-1]);legal=sorted(b.legal_moves,key=lambda x:x.uci())
 for mode in ['R','H']:
  boards=c['history'] if mode=='H' else c['history'][-1:]
  t=get_historical_tokens(deque([tokenize_board(chess.Board(f)) for f in boards],maxlen=8),cfg,0,0,0,0)
  with torch.inference_mode():logits,_,_=model(t.unsqueeze(0),torch.tensor([c['self_elo']]),torch.tensor([c['opponent_elo']]))
  toks=t.numpy();raw=logits[0].numpy();idx=[ix[mirror_move(m.uci()) if b.turn==chess.BLACK else m.uci()] for m in legal]
  p=torch.softmax(logits[0,idx].double(),dim=0).tolist()
  tokens.append(toks);outputs.append(raw);records.append({**c,'mode':mode,'ucis':[m.uci() for m in legal],'indices':idx,'probabilities':p})
np.savez_compressed(root/'results/upstream-reference.npz',tokens=np.stack(tokens),logits=np.stack(outputs))
(root/'results/upstream-reference.json').write_text(json.dumps(records));print('reference cases',len(records),flush=True)
