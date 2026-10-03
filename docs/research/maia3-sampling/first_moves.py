"""Exact conditional first-move probabilities, without Monte Carlo error."""
import json,sys,hashlib,os
from pathlib import Path
import chess,chess.polyglot,numpy as np
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'strength'))
from mobile_policy import Policy,distribution,sha256
b=chess.Board();model=Policy();logits=model.logits(b)
profiles={'argmax':(0.,0.),'current_default':(.5,.9),'full_policy':(1.,1.)}
result={'self_elo':1600,'opponent_elo':1600,'fen':b.fen(),'model_sha256':sha256(model.model),'profiles':{},'books':{}}
for name,(t,p) in profiles.items():
 moves,probs=distribution(b,logits,p,t)
 result['profiles'][name]={'temperature':t,'top_p':p,'probabilities':{b.san(m):float(q) for m,q in zip(moves,probs)}}
for speed,month in [('Blitz','2026-05'),('Rapid','2026-05'),('Rapid','2026-07')]:
 path=Path(os.environ['LICHESS_BOOKS_DIR'])/speed/f'lichess_1600_{speed.lower()}_{month}.bin'
 with chess.polyglot.open_reader(str(path)) as reader:
  entries=list(reader.find_all(b));total=sum(x.weight for x in entries)
  book={b.san(x.move):x.weight/total for x in entries}
 result['books'][f'{speed.lower()}_{month}']={'sha256':sha256(path),'probabilities':book,'total_variation':{name:sum(abs(row['probabilities'].get(m,0)-book.get(m,0)) for m in set(book)|set(row['probabilities']))/2 for name,row in result['profiles'].items()}}
(ROOT/'first-move-probabilities.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({name:row['total_variation'] for name,row in result['books'].items()},indent=2))
