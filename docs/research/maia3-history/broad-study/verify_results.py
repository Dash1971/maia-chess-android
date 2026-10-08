from study import *
from collections import Counter
report={}
for name,file in [('pilot','pilot'),('main','main'),('opening','opening'),('equal','equal-equal'),('challenge','challenge'),('cases','cases')]:
 source={r['id']:r for r in readrows(ROOT/(name+'.jsonl'))};results=readrows(ROOT/'results'/(file+'.jsonl'));assert len(results)==len(source)==len({r['id'] for r in results})
 for r in results:
  s=source[r['id']];b=chess.Board(s['history'][-1]);ucis=sorted(m.uci() for m in b.legal_moves);assert r['ucis']==ucis;assert r['played']==s['played'];j=ucis.index(r['played'])
  for mode in ['R','H']:
   p=np.array(r['p'+mode]);assert np.isfinite(p).all() and (p>=0).all() and abs(p.sum()-1)<1e-10
   assert abs(-math.log(p[j])-r[mode]['nll'])<1e-10
   assert int(np.argmax(p)==j)==r[mode]['accuracy']
   assert abs(np.sum(p*p)-2*p[j]+1-r[mode]['brier'])<1e-10
   assert ucis[np.argmax(p)]==r[mode]['top']
   assert abs(r[mode]['copy_p']-(p[ucis.index(s['copy'])] if s['copy'] in ucis else 0))<1e-10
 report[name]={'rows':len(results),'legal_move_sets_and_metrics_verified':True,'source_sha256':digest(ROOT/(name+'.jsonl')),'result_sha256':digest(ROOT/'results'/(file+'.jsonl'))}
# Original-seed-independent direct re-inference of fixed positions (not selection by outcomes).
model=Model();rows=readrows(ROOT/'main.jsonl');results={r['id']:r for r in readrows(ROOT/'results/main.jsonl')};mx=0
for r in rows[::1000]:
 moves,p=model.both(r);saved=results[r['id']];mx=max(mx,float(np.max(np.abs(p-np.array([saved['pR'],saved['pH']])))))
assert mx<1e-10
report['recomputed']={'n':len(rows[::1000]),'max_probability_difference':mx}
# Validate all tactical child classifications independently from their stored flags.
for name in ['tactical','tactical-deep']:
 rr=[]
 for path in sorted((ROOT/'results').glob(name+'-part[0-9].jsonl')):rr+=readrows(path)
 assert len(rr)==len({r['id'] for r in rr})==(384 if name=='tactical' else 48)
 checked=0
 for r in rr:
  b=chess.Board(r['fen']);assert {v['uci'] for v in r['values']}=={m.uci() for m in b.legal_moves}
  for v in r['values']:
   c=b.copy();c.push_uci(v['uci']);assert c.is_stalemate()==v['stalemate'];assert c.is_checkmate()==v['mate1'];assert c.is_insufficient_material()==v['insufficient'];checked+=1
 report[name]={'positions':len(rr),'legal_children_checked':checked}
report['status']='passed';report['verification_script_sha256']=digest(ROOT/'verify_results.py')
(ROOT/'results/verification.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
