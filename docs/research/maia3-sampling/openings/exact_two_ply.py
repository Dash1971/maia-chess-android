"""Exact book-free two-ply sequence distribution (no Monte Carlo)."""
import json,argparse
from pathlib import Path
import chess,chess.polyglot
from experiment import HERE,Policy,MODEL79,book_distribution,distribution,metrics,SETTINGS

parser=argparse.ArgumentParser();parser.add_argument('--model',type=Path,default=MODEL79);args=parser.parse_args()
policy=Policy(model=args.model,threads=1);result={}
for name in ('lichess_1600_blitz_2026-05','lichess_1600_rapid_2026-05','lichess_1600_rapid_2026-07'):
    reader=chess.polyglot.open_reader(str(HERE/'source'/f'{name}.bin'));root=chess.Board();hp=book_distribution(reader,root);models={}
    for s,(p,t) in SETTINGS.items():
        moves,ps=distribution(root,policy.logits(root),p,t);models[s]={m.uci():float(v) for m,v in zip(moves,ps)}
    human={};model={s:{} for s in SETTINGS}
    for first in root.legal_moves:
        board=root.copy();board.push(first);hm=book_distribution(reader,board)
        for second,prob in hm.items():human[first.uci()+' '+second]=hp.get(first.uci(),0)*prob
        for s,(p,t) in SETTINGS.items():
            moves,ps=distribution(board,policy.logits(board),p,t)
            for m,v in zip(moves,ps):model[s][first.uci()+' '+m.uci()]=models[s].get(first.uci(),0)*float(v)
    assert abs(sum(human.values())-1)<1e-8
    result[name]={'human_distribution':human,'settings':{s:{'distribution':q,**metrics(human,q)} for s,q in model.items()}}
    reader.close()
(HERE/'exact-two-ply.json').write_text(json.dumps(result,indent=2))
for b,x in result.items():print(b,[(s,round(v['tv'],5),round(v['js_bits'],5)) for s,v in x['settings'].items()])
