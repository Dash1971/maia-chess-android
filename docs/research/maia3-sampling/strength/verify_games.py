import argparse,collections,hashlib,json
from pathlib import Path
import chess,chess.pgn
ap=argparse.ArgumentParser();ap.add_argument('directories',nargs='+',type=Path);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();report=[]
for directory in args.directories:
 rows=[json.loads(line) for line in (directory/'games.jsonl').read_text().splitlines()];manifest=json.loads((directory/'manifest.json').read_text());seen=set();colors=collections.Counter();term=collections.Counter();nplies=0
 for row in rows:
  assert row['id'] not in seen;seen.add(row['id']);b=chess.Board()
  for uci in row['moves_uci']:
   m=chess.Move.from_uci(uci);assert m in b.legal_moves,(row['id'],uci,b.fen());b.push(m)
  assert b.fen()==row['final_fen'];assert b.ply()==row['plies'];assert hashlib.sha256(' '.join(row['moves_uci']).encode()).hexdigest()==row['movetext_sha256'];out=b.outcome(claim_draw=True)
  if out:assert out.result()==row['result'];assert out.termination.name.lower()==row['termination']
  else:assert b.ply()==manifest['max_plies'];assert row['termination']=='max_plies'
  colors[(row['first'],row['white']==row['first'])]+=1;term[row['termination']]+=1;nplies+=row['plies']
 pgn=[]
 with (directory/'games.pgn').open() as f:
  while game:=chess.pgn.read_game(f):
   assert not game.errors;pgn.append(game)
 assert len(pgn)==len(rows)
 lookup={r['id']:r for r in rows}
 for g in pgn:
  r=lookup[g.headers['StudyGameId']];assert [m.uci() for m in g.mainline_moves()]==r['moves_uci'];assert g.headers['Result']==r['result']
 report.append({'directory':directory.name,'games':len(rows),'plies_checked':nplies,'illegal_moves':0,'json_pgn_mismatches':0,'terminations':dict(term),'color_counts':{str(k):v for k,v in colors.items()},'manifest_target':manifest['games_per_pair']*(1 if manifest['pair_index'] is not None else 3)})
args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
