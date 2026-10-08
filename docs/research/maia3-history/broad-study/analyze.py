from study import *
from collections import defaultdict,Counter
METRICS=['nll','accuracy','played_p','brier','copy_p','reverse_p']
def clustered(rows,v,seed=2026100902,reps=2000):
 v=np.asarray(v,float)
 if v.ndim==1:v=v[:,None]
 ids=sorted({r['game'] for r in rows});gi={g:i for i,g in enumerate(ids)};ix=np.array([gi[r['game']] for r in rows]);s=np.zeros((len(ids),v.shape[1]));np.add.at(s,ix,v);counts=np.bincount(ix,minlength=len(ids));rng=np.random.default_rng(seed);boot=[]
 for start in range(0,reps,100):
  w=rng.multinomial(len(ids),np.full(len(ids),1/len(ids)),size=min(100,reps-start));boot.append((w@s)/(w@counts)[:,None])
 b=np.concatenate(boot);return np.quantile(b,[.025,.975],axis=0).T.tolist()
def summarize(rows):
 if not rows:return None
 vals=[]
 for r in rows:vals.append([r['H'][k]-r['R'][k] for k in METRICS]+[r['H']['copy_p']-int(r['played']==r['copy']),r['R']['copy_p']-int(r['played']==r['copy']),r['H']['reverse_p']-int(r['played']==r['reverse']),r['R']['reverse_p']-int(r['played']==r['reverse'])])
 cis=clustered(rows,vals)
 out={'n':len(rows),'games':len({r['game'] for r in rows}),'metrics':{}}
 for i,k in enumerate(METRICS):out['metrics'][k]={'R':float(np.mean([r['R'][k] for r in rows])),'H':float(np.mean([r['H'][k] for r in rows])),'difference':float(np.mean(np.array(vals)[:,i])),'ci95':cis[i]}
 out.update({'human_copy':float(np.mean([r['played']==r['copy'] for r in rows])),'human_reverse':float(np.mean([r['played']==r['reverse'] for r in rows])),'copy_available':sum(r['copy'] is not None for r in rows),'reverse_available':sum(r['reverse'] is not None for r in rows),'mean_policy_tv':float(np.mean([r['tv'] for r in rows])),'top_move_changed':float(np.mean([r['R']['top']!=r['H']['top'] for r in rows]))})
 out['calibration']={k:{'difference':float(np.mean(np.array(vals)[:,6+i])),'ci95':cis[6+i]} for i,k in enumerate(['H_copy_minus_human','R_copy_minus_human','H_reverse_minus_human','R_reverse_minus_human'])}
 return out

def sections(rows):
 out={'overall':summarize(rows)}
 for field in ['band','color','stage']:
  out[field]={str(v):summarize([r for r in rows if r[field]==v]) for v in sorted({r[field] for r in rows})}
 out['band_color']={f'{band}-{color}':summarize([r for r in rows if r['band']==band and r['color']==color]) for band in range(4) for color in range(2)}
 return out

def merge():
 rows=[]
 for p in sorted((ROOT/'results').glob('main-part[0-9].jsonl')):rows.extend(readrows(p))
 assert len(rows)==len({r['id'] for r in rows})==20160
 assert {r['id'] for r in rows}=={r['id'] for r in readrows(ROOT/'main.jsonl')}
 writerows(ROOT/'results/main.jsonl',sorted(rows,key=lambda r:r['id']))
 return rows

def tactical_rows(deep=False):
 name='tactical-deep' if deep else 'tactical';data=[]
 for p in sorted((ROOT/'results').glob(name+'-part[0-9].jsonl')):data+=readrows(p)
 assert len(data)==(48 if deep else 384)
 policies={r['id']:r for r in readrows(ROOT/'results/main.jsonl')};out=[]
 for r in data:
  pol=policies[r['id']];vs={v['uci']:v for v in r['values']};assert set(vs)==set(pol['ucis']);v=[vs[m] for m in pol['ucis']];cp=np.array([x['cp'] for x in v]);best=float(cp.max());clip=np.clip(cp,-1000,1000);severe=(best-cp)>=200;stale=np.array([x['stalemate'] for x in v]);mate1=np.array([x['mate1'] for x in v]);j=pol['ucis'].index(r['played'])
  metrics={'loss':clip.max()-clip,'severe':severe,'stalemate':stale,'missed_mate1':~mate1 if mate1.any() else np.zeros(len(v))}
  rr={k:r[k] for k in ['id','game','band','color','stage']};rr.update({'best_cp':best,'viable':best>=-200,'winning':best>=300,'mate1_available':bool(mate1.any()),'human_severe':int(severe[j]),'human_stalemate':int(stale[j]),'human_loss':float(metrics['loss'][j]),'R':{},'H':{},'R95':{},'H95':{}})
  for mode in ['R','H']:
   q=np.array(pol['p'+mode]);q95=nucleus(q)
   rr[mode]={k:float(q@arr) for k,arr in metrics.items()};rr[mode+'95']={k:float(q95@arr) for k,arr in metrics.items()}
  out.append(rr)
 writerows(ROOT/'results'/(name+'-metrics.jsonl'),out)
 return out

def tact_summary(rows):
 if not rows:return {'n':0}
 out={'n':len(rows),'games':len({r['game'] for r in rows})}
 for suffix in ['', '95']:
  keys=['loss','severe','stalemate','missed_mate1'];v=[[r['H'+suffix][k]-r['R'+suffix][k] for k in keys] for r in rows];ci=clustered(rows,v)
  out['p1' if not suffix else 'p95']={k:{'R':float(np.mean([r['R'+suffix][k] for r in rows])),'H':float(np.mean([r['H'+suffix][k] for r in rows])),'difference':float(np.mean(np.array(v)[:,i])),'ci95':ci[i]} for i,k in enumerate(keys)}
 out['human']={k:float(np.mean([r['human_'+k] for r in rows])) for k in ['loss','severe','stalemate']};return out

def main():
 rows=merge();report={'main':sections(rows),'opening':sections(readrows(ROOT/'results/opening.jsonl')),'equal':sections(readrows(ROOT/'results/equal-equal.jsonl'))}
 # Compare equal-input subset to exactly its actual-rating counterpart.
 eqids={r['id'] for r in readrows(ROOT/'results/equal-equal.jsonl')};report['equal_actual_counterpart']=sections([r for r in rows if r['id'] in eqids])
 tactical=tactical_rows();deep=tactical_rows(True)
 for name,rr in [('tactical',tactical),('tactical_deep',deep)]:
  report[name]={label:tact_summary(selected) for label,selected in [('all',rr),('viable',[r for r in rr if r['viable']]),('already_lost',[r for r in rr if not r['viable']]),('winning',[r for r in rr if r['winning']]),('mate1_available',[r for r in rr if r['mate1_available']])]}
  report[name]['band']={str(b):tact_summary([r for r in rr if r['band']==b and r['viable']]) for b in range(4)}
 dids={r['id'] for r in deep};report['tactical_shallow_counterpart']=tact_summary([r for r in tactical if r['id'] in dids])
 shallow_raw={}
 for path in sorted((ROOT/'results').glob('tactical-part[0-9].jsonl')):
  shallow_raw.update({r['id']:r for r in readrows(path)})
 deep_raw=readrows(ROOT/'results/tactical-deep-part0.jsonl');agreements=[];viable_agree=[]
 for d in deep_raw:
  shallow=shallow_raw[d['id']];sv={v['uci']:v['cp'] for v in shallow['values']};dv={v['uci']:v['cp'] for v in d['values']};sb=max(sv.values());db=max(dv.values());viable_agree.append((sb>=-200)==(db>=-200))
  agreements.extend((sb-sv[m]>=200)==(db-dv[m]>=200) for m in sv)
 report['tactical_budget_agreement']={'positions':len(deep_raw),'legal_moves':len(agreements),'severe_label_agreement':float(np.mean(agreements)),'viability_label_agreement':float(np.mean(viable_agree))}
 # Example positions with biggest human likelihood changes, selected after aggregate analysis.
 source={r['id']:r for r in readrows(ROOT/'main.jsonl')};ordered=sorted(rows,key=lambda r:r['H']['nll']-r['R']['nll']);report['illustrations']={}
 for label,chosen in [('history_helped',ordered[:5]),('history_hurt',ordered[-5:])]:
  report['illustrations'][label]=[{**{k:r[k] for k in ['id','game','ply','self_elo','opponent_elo','played','R','H']},'fen':source[r['id']]['history'][-1]} for r in chosen]
 report['selection']=json.loads((ROOT/'selection.json').read_text());report['parity']=json.loads((ROOT/'results/parity.json').read_text());report['analysis_sha256']=digest(ROOT/'analyze.py')
 (ROOT/'results/summary.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:report[k]['overall'] for k in ['main','opening','equal']},indent=2))
if __name__=='__main__':main()
