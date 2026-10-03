import argparse,collections,json
from pathlib import Path
import chess,chess.pgn
from app_draw_sensitivity import key,app_outcome
ap=argparse.ArgumentParser();ap.add_argument('--primary',nargs='+',type=Path,required=True);ap.add_argument('--sensitivity',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();primary={r['id']:r for p in args.primary for r in map(json.loads,p.read_text().splitlines())};rows=list(map(json.loads,(args.sensitivity/'games.jsonl').read_text().splitlines()));assert len(rows)==len(primary)
for r in rows:
 original=primary[r['id']];assert r['moves_uci'][:len(original['moves_uci'])]==original['moves_uci'];b=chess.Board();counts=collections.Counter({key(b):1})
 for uci in r['moves_uci']:
  assert app_outcome(b,counts) is None
  m=chess.Move.from_uci(uci);assert m in b.legal_moves;b.push(m);counts[key(b)]+=1
 outcome=app_outcome(b,counts)
 if outcome:assert outcome==(r['result'],r['termination'])
 else:assert b.ply()==400 and r['termination']=='max_plies'
 assert b.fen()==r['final_fen'];assert b.ply()==r['plies'];sw={'1-0':1.,'1/2-1/2':.5,'0-1':0.}[r['result']];assert r['score_first']==(sw if r['white']==r['first'] else 1-sw)
 assert r['primary_result']==original['result'];assert r['primary_plies']==original['plies']
pgn=[]
with (args.sensitivity/'games.pgn').open() as f:
 while g:=chess.pgn.read_game(f):assert not g.errors;pgn.append(g)
assert len(pgn)==len(rows);lookup={r['id']:r for r in rows}
for g in pgn:
 r=lookup[g.headers['StudyGameId']];assert [m.uci() for m in g.mainline_moves()]==r['moves_uci'];assert g.headers['Result']==r['result']
report={'games':len(rows),'illegal_moves':0,'prefix_mismatches':0,'app_draw_mismatches':0,'pgn_json_mismatches':0,'results_changed':sum(r['result']!=r['primary_result'] for r in rows),'added_plies':sum(r['plies']-r['primary_plies'] for r in rows),'terminations':dict(collections.Counter(r['termination'] for r in rows))};args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
