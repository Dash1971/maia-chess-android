"""Same human-book position sample, Maia3 5M size sensitivity."""
import json,time,argparse
from pathlib import Path
import chess
from experiment import HERE,Policy,distribution,SETTINGS,metrics,sha256
from analyze import conditional_summary
from mobile_policy import MODEL5

parser=argparse.ArgumentParser();parser.add_argument('--model',type=Path,default=MODEL5);args=parser.parse_args()
start=time.time();policy=Policy(args.model,threads=1)
rows=json.loads((HERE/'conditional.json').read_text())
for i,r in enumerate(rows):
    board=chess.Board(r['fen']);l=policy.logits(board);r['settings']={}
    for setting,(p,t) in SETTINGS.items():
        moves,probs=distribution(board,l,p,t);q={m.uci():float(v) for m,v in zip(moves,probs)}
        r['settings'][setting]={'distribution':q,**metrics(r['human'],q)}
    if i%500==0:print('5m',i,'calls',policy.calls,flush=True)
(HERE/'conditional-5m.json').write_text(json.dumps(rows))
(HERE/'summary-5m.json').write_text(json.dumps({'model':str(args.model),'sha256':sha256(args.model),'calls':policy.calls,'seconds':time.time()-start,'conditional':conditional_summary(rows)},indent=2))
