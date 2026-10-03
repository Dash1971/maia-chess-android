"""Compare actual independently sampled game prefixes to exact model sequence probabilities."""
import json,collections
import numpy as np
from experiment import HERE,metrics,SEED
from analyze import marginal
human=json.loads((HERE/'human-sample.json').read_text())
model=json.loads((HERE/'exact-two-ply.json').read_text())['lichess_1600_blitz_2026-05']['settings']
groups={'mean1550-1650_blitz':[r for r in human if 1550<=r['mean_elo']<=1650 and r['speed']=='blitz'],'mean1550-1650_rapid':[r for r in human if 1550<=r['mean_elo']<=1650 and r['speed']=='rapid'],'september2025_mean1500-1700':[r for r in human if 1500<=r['mean_elo']<=1700 and r['date'].startswith('2025-09')]}
out={}
for name,h in groups.items():
    c=marginal(h,2,'prefix');n=sum(c.values());p={k:v/n for k,v in c.items()};keys=sorted(set(p)|set(model['full']['distribution']))
    blocks=collections.defaultdict(collections.Counter)
    for r in h:blocks[r['source_group']][' '.join(r['moves'][:2])]+=1
    matrix=np.array([[b.get(k,0) for k in keys] for b in blocks.values()]);rng=np.random.default_rng(SEED);ids=rng.integers(0,len(matrix),(2000,len(matrix)));hs=matrix[ids].sum(1);hs=hs/hs.sum(1)[:,None]
    out[name]={'games':n,'source_blocks':len(matrix),'human_distribution':p,'settings':{}}
    for s in ('argmax','app_default','full'):
        q=model[s]['distribution'];qv=np.array([q.get(k,0) for k in keys]);tv=abs(hs-qv).sum(1)/2
        out[name]['settings'][s]={**metrics(p,q),'tv_ci95':[float(x) for x in np.quantile(tv,[.025,.975])]}
    dq=np.array([model['app_default']['distribution'].get(k,0) for k in keys]);fq=np.array([model['full']['distribution'].get(k,0) for k in keys]);delta=(abs(hs-fq).sum(1)-abs(hs-dq).sum(1))/2
    out[name]['full_minus_default_tv']={'mean':out[name]['settings']['full']['tv']-out[name]['settings']['app_default']['tv'],'ci95':[float(x) for x in np.quantile(delta,[.025,.975])]}
(HERE/'actual-two-ply.json').write_text(json.dumps(out,indent=2))
for name,b in out.items():print(name,b['games'],[(s,round(v['tv'],5),v['tv_ci95']) for s,v in b['settings'].items()],b['full_minus_default_tv'])
