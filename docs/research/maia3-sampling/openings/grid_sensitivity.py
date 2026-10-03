"""Low-cost separation of temperature and nucleus effects from cached exact policy."""
import json,math,collections
import numpy as np
from experiment import HERE,metrics
rows=json.loads((HERE/'conditional.json').read_text());result={}
for book in sorted({r['book'] for r in rows}):
    group=[r for r in rows if r['book']==book];result[book]={}
    for t in (.5,.75,.9,1):
        for p in (.5,.75,.9,1):
            vals=[]
            for r in group:
                raw=r['settings']['full']['distribution'];keys=sorted(raw,key=raw.get,reverse=True);weights=np.array([raw[k]**(1/t) for k in keys]);weights/=weights.sum()
                count=len(keys) if p==1 else int(np.searchsorted(np.cumsum(weights),p,side='left'))+1
                q={k:float(v/weights[:count].sum()) for k,v in zip(keys[:count],weights[:count])}
                vals.append(metrics(r['human'],q))
            result[book][f'T={t},P={p}']={k:float(np.mean([v[k] for v in vals])) for k in ('tv','js_bits','model_entropy_bits','excluded_human_mass')}
(HERE/'grid-sensitivity.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
