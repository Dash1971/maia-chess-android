"""Independent checks of archived probabilities, distances and draw paths."""
import json,math
from pathlib import Path
import chess
ROOT=Path(__file__).resolve().parent
rows=json.loads((ROOT/'openings/conditional.json').read_text())
max_error=0.0
for row in rows:
 board=chess.Board(row['fen']);legal={m.uci() for m in board.legal_moves}
 human=row['human'];assert set(human)<=legal and abs(sum(human.values())-1)<1e-10
 full=row['settings']['full']['distribution'];assert set(full)==legal
 for name,item in row['settings'].items():
  q=item['distribution'];assert set(q)<=legal and all(x>0 for x in q.values()) and abs(sum(q.values())-1)<1e-10
  keys=set(human)|set(q);tv=sum(abs(human.get(k,0)-q.get(k,0)) for k in keys)/2
  js=0
  for k in keys:
   p1,p2=human.get(k,0),q.get(k,0);mid=(p1+p2)/2
   if p1:js+=.5*p1*math.log2(p1/mid)
   if p2:js+=.5*p2*math.log2(p2/mid)
  err=max(abs(tv-item['tv']),abs(js-item['js_bits']));max_error=max(max_error,err);assert err<1e-10
  assert abs(item['excluded_human_mass']-sum(v for k,v in human.items() if k not in q))<1e-10
 assert next(iter(row['settings']['argmax']['distribution']))==max(full,key=full.get)
 # Independently derive the app baseline from raw policy probabilities.
 squared=sorted(((m,p*p) for m,p in full.items()),key=lambda x:-x[1]);total=sum(p for m,p in squared);mass=0;keep={}
 for m,p in squared:
  keep[m]=p;mass+=p/total
  if mass>=.9:break
 total=sum(keep.values());derived={m:p/total for m,p in keep.items()}
 app=row['settings']['app_default']['distribution'];assert set(app)==set(derived)
 assert max(abs(app[m]-derived[m]) for m in app)<1e-10
out={'observations_checked':len(rows),'unique_board_fens':len({r['fen'] for r in rows}),'books':len({r['book'] for r in rows}),'book_trajectory_pairs':len({(r['book'],r['trajectory']) for r in rows}),'independent_distance_max_error':max_error,'legal_support_and_probability_normalization':'pass','argmax_and_baseline_rederived_from_full_policy':'pass','tv_and_js_recalculation':'pass'}
(ROOT/'opening-validation.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
