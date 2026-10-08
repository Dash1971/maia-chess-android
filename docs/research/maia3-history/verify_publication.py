"""Read-only audit of published bytes, raw probabilities and sampled openings."""
from pathlib import Path
import hashlib,json,math,tarfile
import chess,numpy as np
ROOT=Path(__file__).resolve().parent
def digest(data):return hashlib.sha256(data).hexdigest()
def read(path):return [json.loads(line) for line in path.read_text().splitlines()]
def main():
 for line in (ROOT/'SHA256SUMS').read_text().splitlines():
  expected,rel=line.split('  ',1);assert digest((ROOT/rel).read_bytes())==expected,rel
 archives={}
 for key,expected in json.loads((ROOT/'measurement-hashes.json').read_text()).items():
  if '!/' in key:
   arc,member=key.split('!/',1)
   if arc not in archives:archives[arc]=tarfile.open(ROOT/arc)
   data=archives[arc].extractfile(member).read()
  else:data=(ROOT/key).read_bytes()
  assert digest(data)==expected,key
 for tar in archives.values():tar.close()
 broad=ROOT/'broad-study';counts={}
 summary=json.loads((broad/'results/summary.json').read_text())
 for name,result in [('pilot','pilot'),('main','main'),('opening','opening'),('equal','equal-equal'),('challenge','challenge'),('cases','cases')]:
  inputs={r['id']:r for r in read(broad/(name+'.jsonl'))};rows=read(broad/'results'/(result+'.jsonl'));assert len(inputs)==len(rows)==len({r['id'] for r in rows});counts[name]=len(rows)
  for r in rows:
   s=inputs[r['id']];b=chess.Board(s['history'][-1]);assert r['ucis']==sorted(m.uci() for m in b.legal_moves);assert r['played']==s['played'];j=r['ucis'].index(r['played'])
   for mode in 'RH':
    q=np.array(r['p'+mode]);assert np.isfinite(q).all() and min(q)>=0 and abs(q.sum()-1)<1e-10
    values={'nll':-math.log(q[j]),'played_p':q[j],'accuracy':int(q.argmax()==j),'brier':float(q@q-2*q[j]+1),'copy_p':q[r['ucis'].index(s['copy'])] if s['copy'] in r['ucis'] else 0,'reverse_p':q[r['ucis'].index(s['reverse'])] if s['reverse'] in r['ucis'] else 0}
    for k,v in values.items():assert abs(v-r[mode][k])<1e-10
   assert abs(np.abs(np.array(r['pR'])-r['pH']).sum()/2-r['tv'])<1e-10
  if name in ['main','opening','equal']:
   for k,metric in summary[name]['overall']['metrics'].items():
    for mode in 'RH':assert abs(np.mean([r[mode][k] for r in rows])-metric[mode])<1e-12
 stone=ROOT/'stonewall';policies=read(stone/'policies.jsonl');games=read(stone/'games.jsonl');fixed=read(stone/'fixed.jsonl');sums=json.loads((stone/'summary.json').read_text())
 for p in policies:
  assert p['ucis']==sorted(m.uci() for m in chess.Board(p['history'][-1]).legal_moves)
  for mode in 'RH':assert np.isfinite(p['p'+mode]).all() and min(p['p'+mode])>=0 and abs(sum(p['p'+mode])-1)<1e-10
 plan=['d2d4','e2e3','f1d3','f2f4','g1f3','c2c3','b1d2','e1g1']
 for g in games:
  b=chess.Board();hist=[b.fen()];copies=[];random=np.random.default_rng(2026100907+g['elo']*1000+g['seed']).random(8)
  for ply,u in enumerate(g['moves']):
   m=chess.Move.from_uci(u);assert m in b.legal_moves
   if ply%2:
    p=policies[g['policy_ids'][ply//2]];assert p['elo']==g['elo'] and p['history']==hist[-8:]
    j=min(np.searchsorted(np.cumsum(p['p'+g['mode']]),random[ply//2],side='right'),len(p['ucis'])-1);assert p['ucis'][j]==u
    last=b.peek();copies.append(m==chess.Move(chess.square_mirror(last.from_square),chess.square_mirror(last.to_square)))
   else:assert u==plan[ply//2]
   b.push(m);hist.append(b.fen())
  assert copies==g['copies'] and sum(copies)==g['copy_count'] and len(copies)==g['black_turns']
  for k,n in [('first3',3),('first6',6),('all8',8)]:assert g[k]==(len(copies)>=n and all(copies[:n]))
  longest=run=0
  for v in copies:run=run+1 if v else 0;longest=max(longest,run)
  assert longest==g['longest_run']
  if g['stop']=='script_illegal':assert chess.Move.from_uci(plan[len(copies)]) not in b.legal_moves
 for elo in [600,700]:
  groups={mode:[g for g in games if g['elo']==elo and g['mode']==mode] for mode in 'RH'};assert all(len(rr)==250 for rr in groups.values())
  for key,record in sums[str(elo)].items():
   if key=='stops':
    for mode in 'RH':assert record[mode]==sum(g['stop'] is not None for g in groups[mode])
    continue
   a=np.array([g[key] for g in groups['R']],float);b=np.array([g[key] for g in groups['H']],float)
   ix=np.random.default_rng(2026100908).integers(0,250,(2000,250));ci=np.quantile((b-a)[ix].mean(axis=1),[.025,.975]);assert np.allclose(ci,record['ci'],atol=1e-12)
   assert abs(a.mean()-record['R'])<1e-12 and abs(b.mean()-record['H'])<1e-12 and abs((b-a).mean()-record['delta'])<1e-12
 for elo in [600,700,800,1000,1200]:
  joint=np.ones(2)
  for row in [r for r in fixed if r['elo']==elo]:
   p=policies[row['policy_id']];assert p['elo']==elo and p['history'][-1]==row['fen'];j=p['ucis'].index(row['mirror']);q=np.array([p['pR'][j],p['pH'][j]]);joint*=q
   assert np.allclose(q,[row['pR'],row['pH']],atol=0,rtol=0);assert np.allclose(joint,[row['jointR'],row['jointH']],atol=0,rtol=0)
 print(json.dumps({'status':'passed','broad_records':counts,'stonewall_games':len(games),'stonewall_policies':len(policies),'fixed_prefixes':len(fixed),'measurements_byte_identical':True,'policy_metrics_and_sampled_draws_verified':True},indent=2))
if __name__=='__main__':main()
