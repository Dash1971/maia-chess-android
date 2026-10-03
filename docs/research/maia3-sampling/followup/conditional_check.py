"""Independent aggregate check of the inclusive .95 policy from archived fixtures."""
import collections,json,math,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parent
source=ROOT.parent/'sampling-research-20261002/openings/conditional.json'
rows=json.loads(source.read_text());books=collections.defaultdict(list)
def tv(p,q):return sum(abs(p.get(k,0)-q.get(k,0)) for k in set(p)|set(q))/2
for r in rows:
 raw=r['settings']['full']['distribution'];keys=sorted(raw,key=raw.get,reverse=True);keep=[];mass=0
 for k in keys:
  mass+=raw[k];keep.append(k)
  if mass>=.95:break
 q={k:raw[k]/mass for k in keep};human=r['human'];delta=tv(human,q)-tv(human,raw)
 assert tv(q,raw)<=.05000000000001
 assert abs(tv(q,raw)-(1-mass))<1e-12
 books[r['book']].append({'tv_p95':tv(human,q),'tv_full':tv(human,raw),'tv_previous':r['settings']['app_default']['tv'],'delta_tv':delta,'removed_model_mass':1-mass,'excluded_human_mass':sum(p for k,p in human.items() if k not in q),'entropy_p95':-sum(p*math.log2(p) for p in q.values()),'support_p95':len(q),'support_full':len(raw)})
output={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'observations':len(rows),'books':{}}
for name,vals in books.items():
 summary={k:sum(v[k] for v in vals)/len(vals) for k in vals[0]}
 summary['observations']=len(vals);summary['fraction_closer_than_full']=sum(v['delta_tv']<0 for v in vals)/len(vals)
 summary['fraction_opening_improvement_retained']=(summary['tv_previous']-summary['tv_p95'])/(summary['tv_previous']-summary['tv_full'])
 output['books'][name]=summary
(ROOT/'conditional-check.json').write_text(json.dumps(output,indent=2)+'\n');print(json.dumps(output,indent=2))
