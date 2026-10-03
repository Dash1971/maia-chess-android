"""Fixed-fixture, paired TopP .95 versus full-policy opening analysis."""
import argparse,collections,json,math
from pathlib import Path
import numpy as np
from mobile_policy import sha256
HERE=Path(__file__).resolve().parent
BOOT_SEED=7000003000

def nucleus(q,top_p=.95):
    keys=sorted(q,key=q.get,reverse=True);v=np.array([q[k] for k in keys],dtype=float)
    count=int(np.searchsorted(np.cumsum(v/v.sum()),top_p,side='left'))+1
    return {k:float(x/v[:count].sum()) for k,x in zip(keys[:count],v[:count])}

def metrics(p,q):
    keys=sorted(set(p)|set(q));a=np.array([p.get(k,0) for k in keys]);b=np.array([q.get(k,0) for k in keys]);m=(a+b)/2
    def entropy(v):return float(-sum(x*math.log2(x) for x in v if x>0))
    return {'tv':float(abs(a-b).sum()/2),'js_bits':entropy(m)-(entropy(a)+entropy(b))/2,
            'human_entropy_bits':entropy(a),'model_entropy_bits':entropy(b),
            'excluded_human_mass':sum(v for k,v in p.items() if not q.get(k,0)),
            'human_supported_model_mass':sum(v for k,v in q.items() if p.get(k,0)>0),
            'support':sum(v>0 for v in q.values())}

def summary_group(rows):
    clusters=collections.defaultdict(list)
    for r in rows:clusters[r['trajectory']].append(r)
    groups=list(clusters.values());ns=np.array([len(g) for g in groups]);rng=np.random.default_rng(BOOT_SEED)
    ids=rng.integers(0,len(groups),(2000,len(groups)))
    def estimate(values):
        sums=np.array([sum(values(r) for r in g) for g in groups]);boot=sums[ids].sum(1)/ns[ids].sum(1)
        return {'mean':float(sums.sum()/ns.sum()),'ci95':[float(x) for x in np.quantile(boot,[.025,.975])]},boot
    out={'observations':len(rows),'trajectories':len(groups),'settings':{},'paired_p95_minus_full':{}}
    for s in ('full','full95','app_default'):
        out['settings'][s]={field:estimate(lambda r:r['settings'][s][field])[0] for field in ('tv','js_bits','model_entropy_bits','excluded_human_mass','human_supported_model_mass','support')}
    for field in ('tv','js_bits','model_entropy_bits','excluded_human_mass','human_supported_model_mass','support'):
        out['paired_p95_minus_full'][field]=estimate(lambda r:r['settings']['full95'][field]-r['settings']['full'][field])[0]
    for field in ('tv','js_bits'):
        gain95,boot95=estimate(lambda r:r['settings']['app_default'][field]-r['settings']['full95'][field])
        gain1,boot1=estimate(lambda r:r['settings']['app_default'][field]-r['settings']['full'][field])
        ratio=boot95/boot1;out[f'{field}_old_default_improvement_retained']={'ratio_of_mean_improvements':gain95['mean']/gain1['mean'],'ci95':[float(x) for x in np.quantile(ratio,[.025,.975])]}
    out['mean_removed_model_mass']=float(np.mean([r['removed_model_mass'] for r in rows]));return out

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--source-study',required=True,type=Path);args=ap.parse_args();source=args.source_study.resolve()
    infile=source/'openings/conditional.json';old=json.loads(infile.read_text());rows=[]
    for r in old:
        q=r['settings']['full']['distribution'];q95=nucleus(q);s={k:{**metrics(r['human'],r['settings'][k]['distribution']),'distribution':r['settings'][k]['distribution']} for k in ('full','app_default')}
        s['full95']={**metrics(r['human'],q95),'distribution':q95}
        rows.append({k:r[k] for k in ('book','trajectory','ply','fen','human')}|{'settings':s,'removed_model_mass':1-sum(q[k] for k in q95)})
    (HERE/'conditional95.json').write_text(json.dumps(rows))
    summary={}
    for book in sorted({r['book'] for r in rows}):
        g=[r for r in rows if r['book']==book];d=summary_group(g)
        d['position_coverage_by_ply']={str(p):sum(r['ply']==p for r in g)/150 for p in range(16)}
        d['depth_groups']={f'{a}-{b}':summary_group([r for r in g if a<=r['ply']<=b]) for a,b in ((0,3),(4,7),(0,7),(8,11),(12,15))};summary[book]=d
    (HERE/'conditional-summary95.json').write_text(json.dumps(summary,indent=2))
    exact_path=source/'openings/exact-two-ply.json';ex=json.loads(exact_path.read_text());exact={}
    modeljoint=next(iter(ex.values()))['settings']['full']['distribution'];first=collections.Counter();black=collections.defaultdict(dict)
    for k,v in modeljoint.items():a,b=k.split();first[a]+=v;black[a][b]=v
    first95=nucleus(first);black={a:{b:v/first[a] for b,v in q.items()} for a,q in black.items()};black95={a:nucleus(q) for a,q in black.items()}
    joint95={a+' '+b:pa*pb for a,pa in first95.items() for b,pb in black95[a].items()}
    for book,d in ex.items():
        h=d['human_distribution'];hfirst=collections.Counter();hb=collections.defaultdict(collections.Counter)
        for k,v in h.items():a,b=k.split();hfirst[a]+=v;hb[a][b]+=v
        exact[book]={'first_move':{'human':dict(hfirst),'full':dict(first),'full95':first95,'metrics':{'full':metrics(hfirst,first),'full95':metrics(hfirst,first95)}},'two_ply':{'human':h,'full':modeljoint,'full95':joint95,'metrics':{'full':metrics(h,modeljoint),'full95':metrics(h,joint95),'app_default':metrics(h,d['settings']['app_default']['distribution'])}},'black_after':{}}
        for a in ('e2e4','d2d4'):
            hq={b:v/hfirst[a] for b,v in hb[a].items()};exact[book]['black_after'][a]={'human':hq,'full':black[a],'full95':black95[a],'metrics':{'full':metrics(hq,black[a]),'full95':metrics(hq,black95[a])}}
    (HERE/'exact-policy95.json').write_text(json.dumps(exact,indent=2))
    meta={'source_sha256':{'conditional':sha256(infile),'exact_two_ply':sha256(exact_path),'script':sha256(Path(__file__))},'observations':len(rows),'bootstrap_replicates':2000,'bootstrap_seed':BOOT_SEED,'fixture_policy':'inclusive crossing nucleus, T1/P.95; fixed original human references','new_model_inferences':0}
    (HERE/'conditional-run95.json').write_text(json.dumps(meta,indent=2))
    for book,d in summary.items():print(book,json.dumps({'TV':{s:d['settings'][s]['tv'] for s in d['settings']},'pairedTV':d['paired_p95_minus_full']['tv'],'retained':d['tv_old_default_improvement_retained']}))

if __name__=='__main__':main()
